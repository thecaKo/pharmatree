# Procedimento: nova-frente (criar frente multi-repo consistente)

Use para abrir uma nova frente de trabalho que atravessa 1+ repos, seguindo a
convenção de nomes do helix.

## Entradas necessárias

- `type` — `feat` · `fix` · `refactor` · `chore` · `docs` · `test` · `perf` · `build` · `ci`.
- `slug` — kebab-case curto e descritivo (ex.: `atendimentos-grupos`).
- `repos` — lista de repos raiz envolvidos (nome exato de cada pasta).

Derivados:
- Pasta da frente: `worktrees/<type>-<slug>/`
- Branch (a MESMA em todos os repos): `<type>/<slug>`

Se algum dado faltar, **pergunte** antes de criar.

> **Prompt seco → pergunte o nome.** Se o pedido vier vago (ex.: "preciso iniciar
> um novo projeto", "criar uma frente nova"), **não invente** o nome da pasta/branch.
> Pergunte ao usuário o **nome que deve dar à frente** (o `slug` kebab-case) e, se não
> der para inferir, também o `type`. Pasta e branch derivam disso
> (`worktrees/<type>-<slug>/` e branch `<type>/<slug>`). Só prossiga após a resposta.

> **Sempre pergunte QUAIS repos incluir.** Mesmo que o usuário não tenha
> especificado, **não assuma** a lista de `repos` — descubra os repos disponíveis na
> base (passo 1) e **pergunte explicitamente** ao usuário quais ele quer clonar como
> worktree nesta frente. Só siga para a criação depois da resposta.

## Passos

1. **Posicione-se na raiz da base** (a pasta que contém `worktrees/` e os repos raiz).

1b. **Liste os repos disponíveis e pergunte quais incluir.** Detecte os repos raiz
   (cada subpasta que é um repositório git, excluindo `worktrees/`):

   ```bash
   for d in */; do [ -d "$d/.git" ] && echo "${d%/}"; done
   ```
   Apresente essa lista ao usuário e **pergunte quais repos** ele quer para a frente.
   Use **apenas os repos confirmados** como a lista `repos` dos próximos passos.

2. **Crie a pasta da frente**

   ```bash
   mkdir -p worktrees/<type>-<slug>
   ```

3. **Para cada repo da lista**, crie a worktree já na branch nova, **sempre
   partindo da branch `develop` atualizada do repo raiz** (nunca da branch em que
   o repo raiz estiver no momento). Primeiro atualize `develop`:

   ```bash
   git -C <repo> fetch origin develop
   ```
   Então crie a worktree baseando a branch nova em `origin/develop`:
   ```bash
   git -C <repo> worktree add "worktrees/<type>-<slug>/<repo>" -b "<type>/<slug>" origin/develop
   ```
   Se a branch já existir (frente retomada), troque por:
   ```bash
   git -C <repo> worktree add "worktrees/<type>-<slug>/<repo>" "<type>/<slug>"
   ```
   Se algum repo não tiver a branch `develop`, **pare e pergunte ao usuário** de
   qual branch base partir — não assuma `main`/`master`.

3b. **Copie os arquivos de ambiente** do repo raiz para a worktree, **apenas se
   existirem** (`.env` e `.env.test` ficam fora do git, então não vêm na worktree).
   Para cada repo, copie só o que existir — se não houver, não faça nada:

   ```bash
   for f in .env .env.test; do
     [ -f "<repo>/$f" ] && cp "<repo>/$f" "worktrees/<type>-<slug>/<repo>/$f"
   done
   ```

3c. **Instale as dependências** em cada worktree, detectando o gerenciador pelo
   lockfile (não assuma npm). Rode dentro da pasta da worktree do repo:

   ```bash
   cd "worktrees/<type>-<slug>/<repo>"
   if   [ -f pnpm-lock.yaml ];     then pnpm install
   elif [ -f yarn.lock ];          then yarn install
   elif [ -f package-lock.json ];  then npm ci || npm install
   elif [ -f package.json ];       then npm install
   elif [ -f poetry.lock ];        then poetry install
   elif [ -f requirements.txt ];   then pip install -r requirements.txt
   fi
   ```
   Se o repo não tiver manifesto de dependências reconhecido, pule esta etapa.

4. **Gere o `CLAUDE.md` por-repo-worktree** em cada
   `worktrees/<type>-<slug>/<repo>/CLAUDE.md`, a partir de
   `templates/CLAUDE.worktree.md`, preenchendo: frente, repo origem, branch, papel
   (web/api/neo-api/…), objetivo (1-2 linhas).

5. **Crie o espelho `AGENTS.md`** ao lado de cada `CLAUDE.md`:

   ```bash
   ln -sf CLAUDE.md "worktrees/<type>-<slug>/<repo>/AGENTS.md"
   ```
   Se a ferramenta-alvo não seguir symlink, copie o conteúdo em vez do link.

6. **Atualize o Mapa de frentes ativas** no `CLAUDE.md` raiz: adicione uma linha
   `| <type>-<slug> | <repos> | <type>/<slug> | em andamento — <objetivo> |`.

7. **Reporte** a frente criada, listando os caminhos das worktrees e a branch.

## Validação

- `git -C <repo> worktree list` deve mostrar a nova worktree no caminho correto, na
  branch `<type>/<slug>`, sem `prunable`.
- Confirme que a subpasta tem **o nome exato do repo** (não um apelido).
- Confirme que a branch nova partiu de `develop`: `git -C "worktrees/<type>-<slug>/<repo>"
  merge-base --is-ancestor origin/develop HEAD` deve retornar sucesso (a nova branch
  contém o topo de `origin/develop`).
