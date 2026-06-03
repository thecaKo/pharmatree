# pharmatree

Repositório do framework **pharmatree** (skill + templates + docs para orquestrar
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

## Skill pharmatree

Para orquestração multi-repo (criar frente, localizar-se, commitar, fechar feature,
reparar worktrees), invoque a skill `pharmatree`. Workflow de desenvolvimento usa o
plugin superpowers (brainstorming → writing-plans → TDD → verification →
finishing-a-development-branch).
