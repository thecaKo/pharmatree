# Procedimento: doctor (reparar worktrees + sincronizar mapa)

Use para consertar worktrees `prunable`/quebradas e reconciliar o Mapa de frentes
ativas com a realidade do disco. **Não-destrutivo:** liste e proponha; só renomeie/
mova/remova com confirmação explícita do usuário.

## Passos

1. **Inventário por repo raiz**

   Para cada repo origem na base:
   ```bash
   git -C <repo> worktree list
   ```
   Anote paths, branches e marcações `prunable`.

2. **Reparar paths defasados** (worktrees movidas → `prunable`)

   ```bash
   git -C <repo> worktree repair
   ```
   `repair` reconecta os metadados ao novo caminho. Rode na base inteira se útil:
   ```bash
   git -C <repo> worktree repair worktrees/*/<repo>
   ```

3. **Podar órfãos** (worktree cujo diretório não existe mais) — só após confirmar:

   ```bash
   git -C <repo> worktree prune
   ```

4. **Auditar contra a convenção.** Para cada worktree em `worktrees/<frente>/<repo>`,
   sinalize (sem corrigir automaticamente):
   - subpasta com nome **≠** do repo origem (`git rev-parse --git-common-dir`);
   - branch **≠** esperada (`<frente>` com `-`→`/`);
   - branch protegida (`main`/`master`/`develop`) dentro de uma frente.

   Para cada divergência, **proponha** o comando de correção (renomear pasta, criar/
   trocar branch) e peça confirmação.

5. **Regenerar o Mapa de frentes ativas** no `CLAUDE.md` raiz a partir do estado real:
   uma linha por frente com `| frente | repos | branch | status |`. Preserve os campos
   de objetivo/status já preenchidos manualmente quando possível.

6. **Reporte** um resumo: o que foi reparado, o que foi podado (se confirmado) e a
   lista de divergências pendentes de decisão.

## Lembrete

A fonte da verdade é o git. Este procedimento não inventa estado: ele lê
`worktree list` + `git-common-dir` e ajusta documentação/metadados para refletir o
real.
