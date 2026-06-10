# helix

Repositório do framework **helix** (skill + templates + docs para orquestrar
trabalho multi-repo com git worktrees).

## ⛔ Regra de idioma (prioridade máxima)

**TODA a comunicação entre usuário e IA DEVE ser feita ESTRITAMENTE em português
brasileiro.** A única exceção são termos técnicos e keywords (nomes de
comandos, flags, APIs, nomes de variáveis/funções, palavras-chave de linguagens,
jargão técnico consagrado em inglês), que podem permanecer no original.

## ⛔ Regra: repos raiz SEMPRE em `develop` (prioridade máxima)

**TODOS os repositórios raiz DEVEM permanecer ESTRITAMENTE na branch `develop`.**

- Ao atualizar (`git pull`), localizar-se ou retomar trabalho, garanta que cada
  repo raiz esteja em `develop` — nunca em `main`/`master` ou em qualquer feature
  branch. Se algum estiver fora de `develop`, faça checkout de `develop` (após
  verificar que não há alterações locais pendentes) e dê `git pull --ff-only`.
- Branches de feature vivem nas **worktrees**, não nos repos raiz.
- **Exceção:** repos que comprovadamente não possuem `develop` (atualmente
  `e2e-argo-runner`, `infra-pharma-chat-bot`, `infra-pharma-chat-bot-dev`,
  `infra-pharma-chat-bot-staging`) permanecem em `main`. Não crie `develop` nesses
  sem pedir; se surgir um repo novo sem `develop`, pergunte qual branch base usar.

## ⛔ Regra de design de frontend (prioridade máxima)

**Antes de QUALQUER alteração de design/UI no frontend, carregue o [`design.md`](./design.md)
da raiz e siga-o.**

- Leia o `design.md` **antes** de editar estilos, componentes visuais, telas ou
  qualquer coisa que afete aparência (cores, tipografia, espaçamento, sombras,
  raios, alinhamentos, animações/transições, botões, inputs, cards).
- Use **os tokens existentes** do `design.md` (ex.: `primary-base #e6284a`,
  `CARD_RADIUS 18px`, `SHADOW_MD`, durações de animação, famílias de fonte) em vez
  de introduzir valores avulsos.
- Respeite os **Do's and Don'ts** do `design.md` (ex.: paleta de gráfico nunca em
  UI; toda animação protegida por `prefers-reduced-motion`; nada de cantos vivos em
  cards/inputs/botões).
- Se a mudança exigir um token que ainda não existe, **adicione-o ao `design.md`
  primeiro** e só então use — mantenha o documento como fonte de verdade do design.

O `design.md` cobre as telas **Login**, **Dashboard (v2)** e **PharmaConnector**
do `web-pharmachatbot`.

## ⛔ Regra: alterações no Monday (prioridade máxima)

**TODA e qualquer operação no Monday.com (ler ou alterar itens, colunas, status,
grupos, updates/comentários) DEVE passar pela skill [`monday-api`](./skills/monday-api/SKILL.md).**

- Nunca monte chamadas ad-hoc para `api.monday.com` — use o gateway `monday.sh` da skill.
- Token só via env `MONDAY_API_TOKEN` (nunca hardcoded, nunca no git).
- Operações destrutivas (delete/archive/alterações em massa) exigem confirmação do usuário.

## ⛔ Regra: planos e execução via fast-plan / fast-exec

**Nesta base, [`fast-plan`](./skills/fast-plan/SKILL.md) e
[`fast-exec`](./skills/fast-exec/SKILL.md) SUBSTITUEM as skills
`superpowers:writing-plans`, `superpowers:subagent-driven-development` e
`superpowers:executing-plans`** (instruções do usuário têm prioridade sobre
skills de plugin).

- Fluxo SDD: `superpowers:brainstorming` → **`fast-plan`** → **`fast-exec`** →
  `superpowers:finishing-a-development-branch`.
- O handoff do brainstorming aponta para `fast-plan` (não writing-plans);
  specs vão em `sdd/specs/`, planos em `sdd/plans/` (no hub — `docs/` é repo
  clonado, gitignored).
- Design da decisão: `sdd/specs/2026-06-10-fast-plan-exec-design.md`.

## Mapa de frentes ativas

| Frente | Repos | Branch | Status |
|---|---|---|---|
| feat-atendimentos-v2-reborn | web-pharmachatbot, neo-api-pharmachatbot, api-pharmachatbot, api-baileys-pharmachatbot, messaging-pharmachatbot | feat/atendimentos-v2-reborn | em andamento — tela de Atendimentos v2 ("reborn") sob feature flag |
| feat-dashboard-v2 | web-pharmachatbot, neo-api-pharmachatbot, api-pharmachatbot | feat/dashboard-v2 | em andamento — Dashboard v2 (neo a partir de origin/neo-dashboard; api-pharmachatbot adicionado p/ migration Sequelize do schema `dashboard_outbox_events`) |
| feat-pharma-agent-v2 | pharma-agent-v2, web-pharmachatbot, neo-api-pharmachatbot | feat/pharma-agent-v2 | em andamento — desenvolvimento do pharma-agent-v2 (web + neo) |
| feat-relatorios-v2 | web-pharmachatbot, neo-api-pharmachatbot, api-pharmachatbot | feat/relatorios-v2 | PRs abertas — neo#386, web#1693, api#2005 (tela v2 por flag `relatorios-v2`, 8 relatórios reais); plano em sdd/plans/2026-06-10-relatorios-v2-tasks.md |

## Skill helix

Para orquestração multi-repo (criar frente, localizar-se, commitar, fechar feature,
reparar worktrees), invoque a skill `helix`. Workflow de desenvolvimento usa o
plugin superpowers (brainstorming → writing-plans → TDD → verification →
finishing-a-development-branch).

**Ao criar worktrees, sempre:**
- **Partir da branch `develop`** atualizada do repo raiz (faça `git fetch origin
  develop` e baseie a branch nova em `origin/develop`) — nunca da branch em que o
  repo raiz estiver no momento. Se o repo não tiver `develop`, pergunte qual branch
  base usar (não assuma `main`/`master`).
- **Instalar as dependências** em cada worktree (detectando o gerenciador pelo
  lockfile — pnpm/yarn/npm/poetry/pip — sem assumir npm).
- **Copiar `.env` e `.env.test`** do repo raiz para a worktree **apenas se
  existirem** na raiz; caso contrário, não copiar nada.
