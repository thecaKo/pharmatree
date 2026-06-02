# Framework `multiworktree` — Orquestração multi-repo com worktrees para agentes

**Data:** 2026-06-02
**Status:** Design aprovado (aguardando revisão do spec)

## 1. Problema

O trabalho acontece sobre **vários repositórios ao mesmo tempo** (no mínimo 3 por frente).
Cada frente de trabalho usa git worktrees espalhadas por esses repos. Isso gera quatro
dores recorrentes, todas amplificadas quando 2-3 frentes correm em paralelo:

1. **Commit na pasta errada** — o agente commita no repo origem quando deveria ser na
   worktree, ou mistura mudanças de frentes diferentes.
2. **Não sabe o repo/branch** — o agente (e o próprio dev) não identifica de qual repo
   origem a worktree veio nem qual branch é a correta para aquela frente.
3. **Worktrees defasadas (`prunable`)** — worktrees movidas para dentro de `worktrees/`
   ficam com path defasado no git, gerando estado `prunable` e quebrado.
4. **Criar frente consistente** — falta um padrão para abrir uma nova frente multi-repo
   com nomes/branches coerentes.

Além disso, há uma dor de **orquestração**: ao alternar entre 2-3 frentes, é fácil se
perder — "onde eu estava? o que essa frente envolve?". O framework precisa **impulsionar**
esse fluxo, não só evitar erros.

## 2. Visão

Um **framework abstrato e compartilhável** chamado `multiworktree`: uma convenção de
diretórios + uma hierarquia de `CLAUDE.md` (com espelho `AGENTS.md`) + **uma skill
guarda-chuva** que orienta qualquer agente a saber sempre onde está, retomar uma frente,
criar frentes novas de forma consistente e nunca commitar no lugar errado.

Princípios:

- **Sem scripts shell, sem git hooks, sem pacote npx.** Toda a inteligência mora na skill;
  a execução é o **agente rodando comandos git ao vivo** através das próprias ferramentas.
- **Git como fonte da verdade.** Repo origem e branch são sempre re-derivados do git no
  momento (`git rev-parse`), nunca de um arquivo que pode envelhecer.
- **Foco em agentes (Claude / Codex / Cursor).** Documentação como `CLAUDE.md` + `AGENTS.md`.
- **Abstrato/compartilhável.** O nome `multiworktree` é genérico; a base atual
  (`pharmachatbot/`) é a primeira instância. Copiar a skill + colar o `CLAUDE.md` raiz
  aplica o framework a qualquer base multi-repo.

## 3. Layout de diretórios

```
multiworktree/                          ← raiz do framework · CLAUDE.md = ORQUESTRADOR (+ AGENTS.md)
├── api-pharmachatbot/                  ← repos RAIZ (origem) — NUNCA tocados/commitados
├── web-pharmachatbot/
├── neo-api-pharmachatbot/
├── …  (demais repos origem)
└── worktrees/
    ├── feat-atendimentos-grupos/       ← uma FRENTE (2-3 correm em paralelo)
    │   ├── web-pharmachatbot/          ← worktree · branch feat/atendimentos-grupos
    │   │   ├── CLAUDE.md               ← específico deste repo nesta frente
    │   │   └── AGENTS.md  → CLAUDE.md  (symlink)
    │   ├── neo-api-pharmachatbot/      ← worktree · branch feat/atendimentos-grupos
    │   │   ├── CLAUDE.md
    │   │   └── AGENTS.md  → CLAUDE.md
    │   └── api-pharmachatbot/          ← worktree · branch feat/atendimentos-grupos
    │       ├── CLAUDE.md
    │       └── AGENTS.md  → CLAUDE.md
    └── fix-relatorios-saldo/           ← outra frente
        └── …
```

Regras estruturais:

- A **raiz** não é (necessariamente) um repo git — é o agregador. Os repos origem vivem
  diretamente sob ela e são **imutáveis** no fluxo de trabalho (nunca recebem commit pela
  via do framework).
- Cada **frente** é uma subpasta de `worktrees/`. Dentro dela há **uma subpasta por repo
  envolvido**, e o **nome da subpasta é exatamente o nome do repo origem** (não um apelido)
  — isso elimina ambiguidade sobre a origem.

## 4. Convenção de nomes (conventional commits)

| Elemento | Padrão | Exemplo |
|---|---|---|
| Pasta da frente | `<type>-<slug-kebab>` | `feat-atendimentos-grupos` |
| Branch (igual em **todos** os repos da frente) | `<type>/<slug-kebab>` | `feat/atendimentos-grupos` |
| Subpasta do repo | nome exato do repo origem | `web-pharmachatbot` |
| Mensagem de commit | conventional, **subject-only** + footer Co-Author | `feat: adiciona X` |

- `type` ∈ { `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `build`, `ci` }.
- A pasta usa `-` entre type e slug (caminho plano e legível); a branch usa `/` (100%
  conventional). O mapeamento pasta↔branch é determinístico: trocar o primeiro `-` por `/`.
- A **mesma branch** é usada em todos os repos de uma frente — uma frente = uma branch
  lógica atravessando N repos.

## 5. Hierarquia de documentação (2 níveis)

### 5.1 `CLAUDE.md` raiz — o ORQUESTRADOR

Sempre carregado. É a "boia de salvação" para reorientação. Conteúdo:

1. **Regras de ouro** (instrução de máxima prioridade):
   - Repos raiz **NUNCA** são tocados/commitados — todo trabalho acontece em `worktrees/`.
   - **Antes de QUALQUER commit nesta base, invoque a skill `multiworktree`** e siga o
     checklist de guard.
   - Uma frente = uma branch `<type>/<slug>` atravessando seus repos.
2. **Mapa de frentes ativas** — tabela mantida pela skill (o agente atualiza):

   | Frente | Repos | Branch | Status / objetivo |
   |---|---|---|---|
   | `feat-atendimentos-grupos` | web, neo-api, api | `feat/atendimentos-grupos` | em andamento — … |

3. **Topologia** — como `worktrees/<frente>/<repo>` mapeia para os repos origem.
4. **Ponteiros** — "para se localizar/retomar/criar frente/reparar, invoque a skill
   `multiworktree`".

### 5.2 `CLAUDE.md` por-repo-worktree — o ESPECÍFICO

Em cada `worktrees/<frente>/<repo>/`. Gerado/atualizado pela skill ao criar a frente.
Conteúdo curto:

- **Você está em:** frente `<X>`, repo origem `<Y>`, branch `<type/slug>`, papel
  (`web` / `api` / `neo-api` / …).
- **Objetivo da frente** em 1-2 linhas.
- **Regra local:** commit só aqui, nesta branch; não tocar o repo raiz `<Y>`.

### 5.3 Espelho `AGENTS.md`

Cada `CLAUDE.md` (raiz e por-worktree) ganha um `AGENTS.md` irmão para Codex/Cursor/outros.
**Implementação:** symlink `AGENTS.md → CLAUDE.md` (fonte única). Fallback para cópia caso
alguma ferramenta não siga symlink.

## 6. A skill `multiworktree` (guarda-chuva)

Uma única skill, com procedimentos separados em `references/`. Local:
`.claude/skills/multiworktree/` na raiz do framework (self-contained → compartilhável).

```
.claude/skills/multiworktree/
├── SKILL.md            ← descrição + roteamento para os procedimentos
└── references/
    ├── onde-estou.md   ← localizar-se / retomar frente
    ├── nova-frente.md  ← criar frente nova consistente
    ├── guard.md        ← checklist de pré-commit
    └── doctor.md       ← reparar prunable + regenerar mapa
```

`SKILL.md` — `description` com gatilhos fortes: "onde estou", "qual repo/branch",
"retomar", "antes de commitar", "git commit", "criar frente/worktree", "worktree quebrada".
Roteia para o procedimento certo conforme a intenção.

### 6.1 `onde-estou` (localizar-se / retomar)

1. `git rev-parse --show-toplevel` → caminho da worktree atual.
2. `git rev-parse --git-common-dir` → resolve o **repo origem** real.
3. `git rev-parse --abbrev-ref HEAD` → branch atual.
4. Deriva a frente a partir do caminho (`worktrees/<frente>/<repo>`).
5. Lê o **Mapa de frentes ativas** do `CLAUDE.md` raiz e reporta: "Você está na frente *X*
   (objetivo …), repo origem *Y*, branch *type/slug*. Outras frentes ativas: …".

### 6.2 `nova-frente` (criar frente consistente)

Dado `type`, `slug` e a lista de repos:
1. Cria `worktrees/<type>-<slug>/`.
2. Para cada repo: `git -C <repo-raiz> worktree add worktrees/<type>-<slug>/<repo> -b <type>/<slug>`.
3. Gera `CLAUDE.md` + symlink `AGENTS.md` em cada worktree (seção 5.2).
4. Atualiza o **Mapa de frentes ativas** no `CLAUDE.md` raiz.

### 6.3 `guard` (checklist de pré-commit) — regra: *pasta == branch + protegidas*

Antes de qualquer commit, verificar e **recusar + reportar** se falhar:
1. **Confinamento:** o diretório atual está dentro de `worktrees/<frente>/<repo>` (e não num
   repo raiz)? Mudanças staged não vazam para fora da worktree?
2. **Branch protegida:** a branch **não** é `main` / `master` / `develop`? (bloqueia o caso
   perigoso real — ex.: worktree em `develop`.)
3. **Pasta == branch:** a branch (`<type>/<slug>`) corresponde ao nome da pasta da frente
   (`<type>-<slug>`)? Divergência silenciosa é bloqueada.
4. Se tudo ok: imprime "commitando na frente *X*, repo *Y*, branch *type/slug*" e segue
   (mensagem conventional, subject-only + footer Co-Author).

### 6.4 `doctor` (reparar + sincronizar)

1. `git worktree list` por repo origem; detecta `prunable`.
2. `git worktree repair` nos paths defasados; `git worktree prune` no que for órfão.
3. Reconcilia a árvore real de `worktrees/` com o **Mapa de frentes ativas** e o regenera
   no `CLAUDE.md` raiz.
4. Sinaliza worktrees fora da convenção (pasta≠branch, nome de subpasta ≠ repo origem,
   branch protegida) para correção.

## 7. Cobertura das dores

| Dor | Mecanismo |
|---|---|
| Commit na pasta errada | `guard` (confinamento + protegidas + pasta==branch) |
| Não sabe repo/branch | `onde-estou` (derivação ao vivo via git) + `CLAUDE.md` por-worktree |
| Worktrees `prunable` | `doctor` (`git worktree repair`/`prune`) |
| Criar frente consistente | `nova-frente` (convenção de nomes + geração de docs) |
| Se perder entre 2-3 frentes | `CLAUDE.md` raiz (Mapa de frentes) + `onde-estou` |

## 8. Aplicação à base atual (`pharmachatbot/`) — migração

Estado atual (fora da convenção):

| Pasta atual | Repo origem | Branch atual |
|---|---|---|
| `worktrees/dashbord-v2/neo-dashboard` | `neo-api-pharmachatbot` | `neo-dashboard` |
| `worktrees/dashbord-v2/web-dashboard` | `web-pharmachatbot` | `develop` ⚠️ protegida |
| `worktrees/reports-v2/neo-api-reports-v2` | `neo-api-pharmachatbot` | `neo-api-reports-v2` |
| `worktrees/reports-v2/web-reports-v2` | `web-pharmachatbot` | `web-reports-v2` |

Alvo após `doctor` + renomeação à convenção (exemplo):

```
worktrees/
  feat-dashboard-v2/
    web-pharmachatbot/    (branch feat/dashboard-v2)
    neo-api-pharmachatbot/(branch feat/dashboard-v2)
  feat-reports-v2/
    web-pharmachatbot/    (branch feat/reports-v2)
    neo-api-pharmachatbot/(branch feat/reports-v2)
```

A migração é guiada (não destrutiva): `doctor` lista divergências e propõe os comandos;
nada é renomeado/movido sem confirmação. O caso `web-dashboard` em `develop` é exatamente
o que o `guard` passa a bloquear.

## 9. Fora de escopo (YAGNI)

- Nenhum script shell, git hook ou binário mantido.
- Nenhum pacote npx / runtime Node.
- Nenhum manifesto YAML — git é a fonte da verdade.
- Nenhum CLAUDE.md gerado por **frente** (apenas 2 níveis: raiz + por-repo-worktree).
- Sem automação de push/PR nesta versão (a skill foca em localização, criação, guard e
  reparo; push/PR seguem o fluxo normal do projeto).

## 10. Entregáveis

1. Template do `CLAUDE.md` raiz (orquestrador) + symlink `AGENTS.md` — em pt-br.
2. Skill `multiworktree` (`SKILL.md` + 4 referências) em `.claude/skills/multiworktree/`.
3. Template do `CLAUDE.md` por-repo-worktree (gerado pela skill).
4. Aplicação à base `pharmachatbot/`: `CLAUDE.md` raiz preenchido com o Mapa de frentes
   atuais e migração guiada das worktrees existentes à convenção.
