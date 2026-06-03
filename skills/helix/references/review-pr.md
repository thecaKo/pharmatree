# Procedimento: review-pr (review multi-agente por dimensão)

Use **ao criar a PR de um repo** (após implementar o plano e ter aprovação do
usuário) ou ao revisar uma PR já aberta. Cria a PR no **padrão do projeto**, dispara
um **subagente read-only por dimensão** (em paralelo), consolida os achados, aplica
os fixes por severidade, roda regressão e **itera no máximo 2 vezes**. Encerra
commitando os fixes, postando **um comentário por achado** na PR (com marcação
`APLICADO`/`NÃO APLICADO`) e entregando um resumo. **Nunca faz merge** e **nunca sobe
infra**.

Escopo: **uma rodada por PR/repo** — opera sobre o diff de um único repo.

## Passos

### 1. Pré-condição (`where-am-i`)

Confirme o contexto com `where-am-i`. A worktree atual DEVE estar em
`worktrees/<frente>/<repo>/`, na branch `<type>/<slug>`. Se estiver num repo raiz
ou em branch protegida → **pare** (mesmas regras do `guard`).

```bash
git rev-parse --show-toplevel        # dentro de worktrees/<frente>/<repo>
git rev-parse --abbrev-ref HEAD      # <type>/<slug>
gh pr view --json number,baseRefName,headRefName,url   # já existe PR?
```

### 1.1. Criar a PR (padrão do projeto)

**Antes de tudo, exija autenticação do `gh`:**

```bash
gh auth status
```

Se o `gh` **não estiver autenticado** (comando falha / "not logged in") →
**TRAVE e retorne**:

> ⛔ `gh` não autenticado. Rode `gh auth login` (ou `! gh auth login` neste chat)
> antes de criar/revisar a PR. Veja o Setup do framework (README) para instalar e
> logar o GitHub CLI.

Não tente criar a PR sem autenticação.

Se **ainda não existe** PR para a branch atual (e o plano já foi implementado e
**aprovado pelo usuário**), crie-a seguindo o **padrão fixo**:

- **head** = **branch atual** (`<type>/<slug>`).
- **base** = **`develop`**.
- Usar o **template de PR** do repo (`.github/PULL_REQUEST_TEMPLATE.md`, se existir)
  como corpo, preenchido.

```bash
gh pr create --base develop --head "$(git rev-parse --abbrev-ref HEAD)" \
  --title "<conventional, pt-br>" --body-file .github/PULL_REQUEST_TEMPLATE.md
```

> **⛔ Base e destino são fixos (`branch atual → develop`).** Só troque a base ou o
> destino se isso estiver **EXPLICITAMENTE escrito no prompt** do usuário (ex.:
> "abra a PR para `main`"). Sem instrução explícita, **sempre** `develop`.

Se a PR já existir, siga direto para o passo 2.

### 2. Coleta do diff

Pegue o diff da PR e detecte se toca frontend:

```bash
base=$(gh pr view --json baseRefName -q .baseRefName)
git diff "origin/$base...HEAD" --stat
git diff "origin/$base...HEAD"
```

**Toca frontend?** Se algum arquivo alterado pertence a um repo/UI de frontend
(ex.: `web-pharmachatbot`, ou extensões `.tsx`/`.vue`/`.css`/`.scss` de tela) →
**ative o agente design/UI**; caso contrário, **não** o dispare.

### 3. Fan-out — um subagente read-only por dimensão

Use `superpowers:dispatching-parallel-agents` (ferramenta `Agent`) para disparar,
**em paralelo**, um subagente por dimensão. **Todos são read-only**: apenas
reportam achados, **nunca editam arquivos** (a aplicação de fixes é feita depois,
sequencialmente, por você — evita conflito de escrita no worktree).

Dimensões:

| Agente | Foco |
|---|---|
| **lógica** | bugs, edge cases, null/undefined, off-by-one, condições erradas, race conditions |
| **padrões** | padrões do repo, SOLID, acoplamento, reuso, nomenclatura, estrutura |
| **testes** | cobertura do diff, casos faltando, testes frágeis, se validam o comportamento |
| **performance** | N+1, vazamento de memória, loops custosos, re-renders, bundle size |
| **segurança** | injeção, secrets vazados, authz/authn, validação de input, deps vulneráveis |
| **design/UI** | *só se toca frontend* — aderência aos tokens e regras do `design.md` |

**Brief de cada subagente** (autossuficiente): inclua o diff (ou os hunks
relevantes), o caminho absoluto do repo, a dimensão e a rubrica de severidade.
Regras do projeto a embutir no brief quando se aplicarem:

- **`neo-api`:** o agente consulta a **documentação do repo primeiro**; recorre ao
  código-fonte só se precisar de mais contexto (economiza tokens).
- **design/UI:** o agente carrega o `design.md` da raiz e confere os tokens
  existentes (ex.: `primary-base #e6284a`, `CARD_RADIUS 18px`, `SHADOW_MD`) e os
  Do's & Don'ts — nunca inventa valores avulsos.

Cada subagente retorna **apenas** achados estruturados, um por item:

```
- arquivo: <path relativo ao repo>
  linha: <número ou intervalo>
  dimensão: <logica|padroes|testes|performance|seguranca|design>
  severidade: <low|medium|high>
  descrição: <o problema, objetivo>
  fix_sugerido: <mudança concreta>
```

### 4. Consolidação

Junte os achados de todos os agentes e **deduplique**: mesma linha apontada por
várias dimensões vira **um** item (registre as dimensões que convergiram).

### 5. Aplicação por severidade

- **low / medium →** aplique o fix **automaticamente** no worktree (edições
  sequenciais, você mesmo). Marca → `APLICADO`.
- **high (regra de negócio) →** **NÃO aplique**. São achados que mudam regra de
  negócio / comportamento observável do produto, ou decisão de arquitetura não
  trivial. Para cada um: **peça permissão explícita** antes de qualquer edição.
  Marca → `NÃO APLICADO`.

**Independente da severidade, TODO achado vira comentário na PR** (passo 8) — o que
muda é só a marcação (`APLICADO` para os que você corrigiu, `NÃO APLICADO` para os
que ficaram pendentes/aguardando permissão).

### 6. Regressão (após aplicar os fixes)

Rode a **regressão completa** do repo desta worktree:

1. **Unitários** — bateria do `guard` (comando do `CLAUDE.md` da worktree, campo
   "Testes unitários"; detecte o gerenciador pelo lockfile — pnpm/yarn/npm/
   poetry/pip).
2. **Lint + typecheck** do repo.
3. **Integração** — *somente se o ambiente já estiver de pé* (mesma regra do
   `finish-feature`: o agente **observa**, nunca **provisiona** infra).

Aplique `superpowers:verification-before-completion`: só afirme "passou" com a saída
real em mãos. Se algo quebrar → `superpowers:systematic-debugging`.

### 7. Loop (máx. 2 iterações)

Se a regressão **quebrou** algo, **ou** surgiram **novos achados acionáveis** após
os fixes → **repita** a partir do passo 3 (re-dispare os agentes sobre o diff
atualizado).

**Máximo de 2 iterações.** Na 2ª, **encerre** mesmo que restem pendências — elas
viram itens reportados (passos 8 e 9), não bloqueio.

### 8. Comentários na PR — **1 comentário = 1 problema**

Poste **todos os achados** como comentários na PR via `gh`, **independente da
severidade** (low, medium ou high). Regras:

- **1 comentário = 1 problema.** Não junte vários achados num comentário só.
- **Filtre e concatene os parecidos.** Achados que são o **mesmo problema** (mesma
  causa, mesmo arquivo/área, ou que se resolvem com o mesmo fix) viram **um único**
  comentário. Use isso para reduzir ruído.
- **Máximo de 10 comentários por PR.** Se após a deduplicação/concatenação sobrarem
  mais de 10, **priorize por severidade** (high > medium > low) e **agrupe o
  excedente** em comentários temáticos até caber no teto. Nunca ultrapasse 10.
- **Cada comentário começa com a marcação:**
  - `✅ APLICADO` — fix já aplicado no worktree (low/medium).
  - `⛔ NÃO APLICADO` — pendente; high de regra de negócio aguardando permissão, ou
    excedente não corrigido. Para os HIGH, inclua o **pedido de permissão** para
    aplicar.

**Formato de cada comentário:**

```
<✅ APLICADO | ⛔ NÃO APLICADO> · <dimensão> · <severidade>

<descrição objetiva do problema>

Fix: <o que foi feito, ou o que se sugere fazer>
```

Poste preferencialmente **inline** (ancorado em `arquivo:linha`); caia para
comentário geral da PR só quando a âncora não se aplicar.

### 9. Encerramento

- **Commit dos fixes aplicados** — siga o `guard`: rode o checklist do `guard`
  (confinamento, pasta==branch, unit verdes), e commite em **pt-br**, **conventional
  commits**, **subject-only** + footer Co-Author. Ex.:
  `fix: corrige edge cases apontados no review da PR`.
- **Resumo no chat** — tabela por **dimensão × severidade** (aplicados × pendentes),
  nº de comentários postados (lembrando: teto de 10), nº de iterações e status da
  regressão.
- **Não faça merge.** Para fechar a branch, use `finish-feature` /
  `superpowers:finishing-a-development-branch`.

## Regra de ouro

Os subagentes **só observam e reportam**; quem edita é o orquestrador, e só nas
severidades low/medium. **HIGH (regra de negócio) sempre pede permissão.** **Todo
achado vira comentário na PR (1 comentário = 1 problema, marcado `APLICADO`/`NÃO
APLICADO`), concatenando os parecidos e no máximo 10 por PR.** Nunca mais que **2
iterações**. Nunca merge, nunca subir infra.
