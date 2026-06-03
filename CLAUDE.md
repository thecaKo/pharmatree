# helix

Repositório do framework **helix** (skill + templates + docs para orquestrar
trabalho multi-repo com git worktrees).

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

## Mapa de frentes ativas

| Frente | Repos | Branch | Status |
|---|---|---|---|
| feat-atendimentos-v2-reborn | web-pharmachatbot, neo-api-pharmachatbot, api-pharmachatbot, api-baileys-pharmachatbot, messaging-pharmachatbot | feat/atendimentos-v2-reborn | em andamento — tela de Atendimentos v2 ("reborn") sob feature flag |
| feat-dashboard-v2 | web-pharmachatbot, neo-api-pharmachatbot | feat/dashboard-v2 | em andamento — Dashboard v2 (neo padronizado a partir de origin/neo-dashboard) |
| feat-pharma-agent-v2 | pharma-agent-v2, web-pharmachatbot, neo-api-pharmachatbot | feat/pharma-agent-v2 | em andamento — desenvolvimento do pharma-agent-v2 (web + neo) |

## Skill helix

Para orquestração multi-repo (criar frente, localizar-se, commitar, fechar feature,
reparar worktrees), invoque a skill `helix`. Workflow de desenvolvimento usa o
plugin superpowers (brainstorming → writing-plans → TDD → verification →
finishing-a-development-branch).

**Ao criar worktrees, sempre:**
- **Instalar as dependências** em cada worktree (detectando o gerenciador pelo
  lockfile — pnpm/yarn/npm/poetry/pip — sem assumir npm).
- **Copiar `.env` e `.env.test`** do repo raiz para a worktree **apenas se
  existirem** na raiz; caso contrário, não copiar nada.
