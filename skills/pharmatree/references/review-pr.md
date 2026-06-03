# Procedimento: review-pr (review multi-agente por dimensão)

Use **após abrir a PR de um repo** de uma frente. Dispara um **subagente read-only
por dimensão** (em paralelo), consolida os achados, aplica os fixes por severidade,
roda regressão e **itera no máximo 2 vezes**. Encerra commitando os fixes, postando
comentários inline na PR e entregando um resumo. **Nunca faz merge** e **nunca sobe
infra**.

Escopo: **uma rodada por PR/repo** — opera sobre o diff de um único repo.

## Passos

### 1. Pré-condição (`where-am-i`)

Confirme o contexto com `where-am-i`. A worktree atual DEVE estar em
`worktrees/<frente>/<repo>/`, na branch `<type>/<slug>`, e a PR DEVE existir:

```bash
git rev-parse --show-toplevel        # dentro de worktrees/<frente>/<repo>
git rev-parse --abbrev-ref HEAD      # <type>/<slug>
gh pr view --json number,baseRefName,headRefName,url
```

Se não houver PR aberta para esta branch → **pare e reporte** (este procedimento
revisa PR; abra a PR primeiro). Se estiver num repo raiz ou em branch protegida →
**pare** (mesmas regras do `guard`).

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
  sequenciais, você mesmo).
- **high (regra de negócio) →** **NÃO aplique**. São achados que mudam regra de
  negócio / comportamento observável do produto, ou decisão de arquitetura não
  trivial. Para cada um: poste comentário inline na PR (passo 8) e **peça permissão
  explícita** antes de qualquer edição.

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

### 8. Comentários inline na PR

Poste os achados como comentários inline na PR via `gh`, destacando os **HIGH
pendentes** com o pedido de permissão para aplicar.

### 9. Encerramento

- **Commit dos fixes aplicados** — siga o `guard`: rode o checklist do `guard`
  (confinamento, pasta==branch, unit verdes), e commite em **pt-br**, **conventional
  commits**, **subject-only** + footer Co-Author. Ex.:
  `fix: corrige edge cases apontados no review da PR`.
- **Resumo no chat** — tabela por **dimensão × severidade** (aplicados × pendentes),
  nº de iterações e status da regressão.
- **Não faça merge.** Para fechar a branch, use `finish-feature` /
  `superpowers:finishing-a-development-branch`.

## Regra de ouro

Os subagentes **só observam e reportam**; quem edita é o orquestrador, e só nas
severidades low/medium. **HIGH (regra de negócio) sempre pede permissão.** Nunca
mais que **2 iterações**. Nunca merge, nunca subir infra.
