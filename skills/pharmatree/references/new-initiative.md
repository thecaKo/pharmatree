# Procedimento: nova-frente (criar frente multi-repo consistente)

Use para abrir uma nova frente de trabalho que atravessa 1+ repos, seguindo a
convenção de nomes do pharmatree.

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

3. **Para cada repo da lista**, crie a worktree já na branch nova:

   ```bash
   git -C <repo> worktree add "worktrees/<type>-<slug>/<repo>" -b "<type>/<slug>"
   ```
   Se a branch já existir (frente retomada), troque por:
   ```bash
   git -C <repo> worktree add "worktrees/<type>-<slug>/<repo>" "<type>/<slug>"
   ```

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
