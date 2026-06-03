<!--
  TEMPLATE — CLAUDE.md raiz (ORQUESTRADOR) do framework pharmatree.
  Copie para a raiz da sua base multi-repo como CLAUDE.md e crie AGENTS.md como
  symlink:  ln -sf CLAUDE.md AGENTS.md
  Substitua os campos <...> e mantenha o Mapa de frentes atualizado (a skill faz isso).
-->

# <NOME-DA-BASE> — Orquestrador pharmatree

Esta pasta é a **raiz** de uma base multi-repo organizada com o framework
**pharmatree**. Ela agrega os repositórios de origem e as worktrees de cada frente
de trabalho. **Este arquivo é seu mapa de orquestração** — use-o para se reorientar
quando estiver alternando entre frentes.

## ⛔ Regras de ouro (prioridade máxima)

1. **Repos raiz NUNCA são tocados/commitados.** Todo trabalho acontece em
   `worktrees/<frente>/<repo>/`.
2. **Uma frente = uma branch** `<type>/<slug>` (conventional commits), a **mesma**
   em todos os repos daquela frente.
3. **Antes de QUALQUER commit nesta base, invoque a skill `pharmatree`** e siga o
   procedimento `guard` — que **roda os testes unitários** (devem passar) antes de commitar.
4. **Commits em pt-br**, conventional commits, **subject-only** (sem body) + footer Co-Author.
5. **Ao fim de cada feature**, invoque `pharmatree` → `finish-feature` (testes de
   integração; só rodam se o ambiente já estiver pronto — o agente não sobe infra).
6. **Workflow de desenvolvimento usa o [superpowers](https://github.com/obra/superpowers)**
   (brainstorming → writing-plans → TDD → verification → finishing-a-development-branch).
7. Se você se perder ("onde estou? que repo/branch é esse?"), invoque a skill
   `pharmatree` → procedimento `where-am-i`.

## Topologia

```
<base>/
├── <repo-a>/  <repo-b>/  <repo-c>/   ← repos RAIZ (origem) — imutáveis
└── worktrees/
    └── <type>-<slug>/                ← frente · branch <type>/<slug>
        ├── <repo-a>/  ├── <repo-b>/  ├── <repo-c>/
```

Convenção: pasta `<type>-<slug>` ↔ branch `<type>/<slug>` (primeiro `-` vira `/`).
Subpasta = **nome exato** do repo origem. Commits: conventional, subject-only +
footer de co-autoria.

## 🗺️ Mapa de frentes ativas

<!-- Mantido pela skill pharmatree (procedimentos nova-frente / doctor). -->

| Frente | Repos | Branch | Status / objetivo |
|---|---|---|---|
| `<type>-<slug>` | `<repo-a>`, `<repo-b>` | `<type>/<slug>` | em andamento — <objetivo> |

## Repos de origem

| Repo | Papel |
|---|---|
| `<repo-a>` | <ex.: web/frontend> |
| `<repo-b>` | <ex.: api/backend> |
| `<repo-c>` | <ex.: neo-api> |

## Skill `pharmatree`

| Preciso… | Procedimento |
|---|---|
| me localizar / retomar uma frente | `where-am-i` |
| criar uma frente nova multi-repo | `new-initiative` |
| commitar (checklist + unit tests) | `guard` |
| fechar feature (integration tests) | `finish-feature` |
| consertar worktree quebrada / sincronizar este mapa | `doctor` |
