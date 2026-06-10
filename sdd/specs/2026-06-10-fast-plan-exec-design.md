# fast-plan + fast-exec — Design

**Data:** 2026-06-10
**Status:** aprovado pelo usuário (brainstorming superpowers)

## Problema

O ciclo atual de SDD com superpowers demora demais na **execução de planos**:

1. **Cerimônia por task** — cada task de 2–5 min dispara 3+ subagentes sequenciais
   (implementador → revisor de spec → revisor de qualidade, com loops de re-review).
   Um plano de 12 tasks vira 36–50 dispatches em série.
2. **Paralelismo proibido** — `subagent-driven-development` veta implementadores em
   paralelo, mesmo para tasks com arquivos disjuntos.
3. **Trabalho duplicado** — `writing-plans` exige código completo em cada step do
   plano; o implementador depois refaz tudo via TDD.
4. **Contexto frio** — cada subagente nasce do zero e re-explora o repo.

Inspiração: spec-kit (GitHub), em que o `tasks.md` é o contrato de execução, com
marcadores `[P]` para tasks paralelizáveis e ordenação por dependência.
Decisão estratégica: **absorver as ideias** do spec-kit em skills próprias deste
repo — sem adotar o CLI `specify` nem os comandos `/speckit.*`.

## Objetivo

Reduzir o wall-clock de execução de planos em ~3–5× mantendo os gates de
qualidade essenciais (TDD, review com Opus, fix-loop, regras helix).

## Decisões (com o usuário)

- **Review por fase** (camada de dependência), não por task.
- **Paralelismo na mesma worktree** para tasks `[P]` com arquivos disjuntos.
- **Tiering de modelos**: tasks mecânicas em modelo rápido; integração/julgamento
  e reviews em Opus. (Exceção registrada à regra "todo código via Opus 4.7".)

## Design

### 1. Skill `fast-plan` — formato do plano

Substitui `superpowers:writing-plans` no uso diário desta base.
Salva em `sdd/plans/YYYY-MM-DD-<feature>-tasks.md` (no hub pharmatree;
`docs/` é um repo clonado da base e está gitignored — specs e planos do
framework vivem em `sdd/`).

Estrutura do documento:

- **Header**: goal (1 frase), arquitetura (2–3 frases), stack.
- **Context Pack** (novo): comandos de teste/lint/build do repo, convenções
  relevantes e mapa dos arquivos que serão tocados (1 linha por arquivo).
  Escrito uma única vez e injetado verbatim em todo subagente.
- **Tasks** no formato:

```markdown
### T3 [P] [fast] — Validador de payload  (camada L2, depende: T1)
**Arquivos:** Create: src/validators/payload.ts · Test: tests/validators/payload.test.ts
**Aceitação:** aceita X; rejeita Y com erro Z
**Testes:** nomes/casos de teste esperados (sem o código deles)
**Design:** só quando houver decisão não-óbvia (aí sim com snippet)
```

Regras:

- `[P]` exige arquivos **disjuntos** entre as tasks `[P]` da mesma camada;
  o self-review do plano valida essa disjunção.
- Tier por task: `[fast]` (mecânica: 1–2 arquivos, spec completa) ou `[opus]`
  (integração, julgamento, multi-arquivo).
- **Proibido código completo nos steps** (inversão do writing-plans); código só
  em **Design**, quando a decisão não for óbvia.
- Camadas de dependência L1 → L2 → … ; toda task declara sua camada e
  dependências.

### 2. Skill `fast-exec` — protocolo de execução

Substitui `superpowers:subagent-driven-development` no uso diário desta base.

1. Lê o plano **uma vez**, valida a disjunção de arquivos das `[P]`, cria
   TodoWrite com todas as tasks.
2. **Por camada (L1 → L2 → …):** dispara todas as tasks `[P]` da camada **em
   paralelo** (Agent tool, mesma worktree), cada uma recebendo: texto completo
   da task + Context Pack + instrução de TDD
   (`superpowers:test-driven-development`). Tasks sem `[P]` rodam em série
   dentro da camada. Modelo conforme o tier da task.
3. **Subagentes não commitam** (paralelos brigariam pelo index do git): cada um
   implementa, roda os próprios testes e reporta
   DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED.
   O **controlador commita por task** ao fim da camada (arquivos disjuntos
   permitem um commit limpo por task) — histórico bisectável preservado.
4. **Gate da camada:** roda a suíte de testes relevante à camada inteira; depois
   **um único review Opus** cobrindo spec-compliance + qualidade sobre o diff da
   camada. Reprovou → subagente de fix → re-review. Aprovou → próxima camada.
5. **Fim do plano:** suíte completa +
   `superpowers:finishing-a-development-branch` (inalterado).

Override opcional: o usuário pode pedir review por task em vez de por camada
(ex.: código sensível) — a skill documenta como ativar.

Tratamento de status (herdado do subagent-driven-development):

- **NEEDS_CONTEXT** → fornecer contexto e re-dispachar.
- **BLOCKED** → escalar modelo, quebrar a task, ou parar e perguntar ao usuário.
- Nunca re-dispachar o mesmo modelo sem mudar nada.

### 3. Gates de qualidade — o que fica e o que sai

| Fica | Sai |
|---|---|
| TDD dentro de cada subagente | Review duplo por task (vira único por camada) |
| Review com Opus + fix-loop até aprovar | Código completo no plano |
| Proibição de implementar em repo raiz (helix) | Dispatches sequenciais para tasks independentes |
| Statuses BLOCKED/NEEDS_CONTEXT | Re-exploração do repo por subagente (Context Pack) |

Estimativa para um plano típico (12 tasks, 3 camadas): de ~36 dispatches
sequenciais para ~12 paralelos + 3 reviews.

### 4. Integração

- Skills em `skills/fast-plan/` e `skills/fast-exec/` + symlinks em
  `.claude/skills/` (padrão do repo).
- Fluxo: `superpowers:brainstorming` → **`fast-plan`** → **`fast-exec`** →
  `superpowers:finishing-a-development-branch`.
- CLAUDE.md ganha nota: nesta base, `fast-plan`/`fast-exec` substituem
  `writing-plans`/`subagent-driven-development`, e o handoff do brainstorming
  aponta para `fast-plan`.
- Memória "dispatch-opus-47-for-code" atualizada com a exceção de tiering.
- **Evolução futura (fora de escopo):** orquestrar a execução via Workflow tool
  do Claude Code (`pipeline()`/`parallel()`) para planos com 15+ tasks —
  documentado na `fast-exec` como upgrade opcional.

## Fora de escopo

- Adoção do CLI `specify` / comandos `/speckit.*`.
- Mudanças no brainstorming, using-git-worktrees e
  finishing-a-development-branch do superpowers.
- Constitution file do spec-kit (o CLAUDE.md já cumpre esse papel).

## Riscos e mitigações

- **Conflito entre subagentes paralelos** → disjunção de arquivos validada no
  plano e re-validada pela fast-exec antes de dispachar; commits centralizados
  no controlador.
- **Queda de qualidade por menos reviews** → review por camada mantém Opus no
  gate; se a taxa de reprovação subir, o usuário pode reativar review por task
  pontualmente (a fast-exec aceita override).
- **Agente cair no fluxo antigo do superpowers** → nota explícita no CLAUDE.md
  (prioridade de instruções do usuário sobre skills do plugin) + descrições de
  trigger fortes nas duas skills.
