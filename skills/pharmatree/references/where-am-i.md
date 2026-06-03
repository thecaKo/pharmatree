# Procedimento: onde-estou (localizar-se / retomar frente)

Use quando precisar descobrir onde está, qual repo/branch, ou retomar uma frente
depois de alternar entre tarefas.

## Passos

1. **Caminho da worktree atual**

   ```bash
   git rev-parse --show-toplevel
   ```
   Se o caminho **não** estiver dentro de `worktrees/<frente>/<repo>`, você
   provavelmente está num **repo raiz** — pare e avise: nenhum trabalho/commit
   deve acontecer aqui.

2. **Repo origem real**

   ```bash
   git rev-parse --git-common-dir
   ```
   O diretório `.git` retornado pertence ao repo raiz de origem (ex.:
   `…/web-pharmachatbot/.git` → repo origem `web-pharmachatbot`).

3. **Branch atual**

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

4. **Derive a frente** do caminho: em `worktrees/<frente>/<repo>`, `<frente>` é a
   penúltima pasta. A branch esperada é `<frente>` com o primeiro `-` virando `/`.

5. **Leia o Mapa de frentes ativas** no `CLAUDE.md` raiz da base (sobir até achar a
   pasta que contém `worktrees/`). Cruze a frente atual com o mapa para recuperar o
   objetivo e os outros repos envolvidos.

6. **Reporte** de forma curta:

   > Você está na frente **`<type>-<slug>`** (objetivo: …), repo origem
   > **`<repo>`**, branch **`<type>/<slug>`**.
   > Outros repos desta frente: …. Outras frentes ativas: ….

## Checagem rápida de coerência

- Branch == nome da pasta da frente (com `-`→`/`)? Se não, avise (divergência).
- Branch é `main`/`master`/`develop`? Se sim, **alerta**: você não deveria
  trabalhar/commitar numa branch protegida dentro de uma worktree de frente.
