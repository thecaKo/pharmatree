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
   procedimento `guard`.
4. Se você se perder ("onde estou? que repo/branch é esse?"), invoque a skill
   `pharmatree` → procedimento `onde-estou`.

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
| me localizar / retomar uma frente | `onde-estou` |
| criar uma frente nova multi-repo | `nova-frente` |
| commitar (checklist obrigatório) | `guard` |
| consertar worktree quebrada / sincronizar este mapa | `doctor` |
