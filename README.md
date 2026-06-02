# pharmatree

Framework leve para **orquestrar trabalho em múltiplos repositórios ao mesmo tempo**
usando git worktrees, focado em agentes (Claude / Codex / Cursor). Sem scripts shell,
sem git hooks, sem runtime: a inteligência mora numa **skill** e a verdade vem sempre
do **git ao vivo**.

## Por que

Quando uma frente de trabalho atravessa 3+ repositórios, é fácil:

- commitar no repo errado (origem em vez da worktree);
- não saber em que repo/branch você está;
- acumular worktrees `prunable` (paths defasados);
- abrir frentes novas de forma inconsistente;
- se perder ao alternar entre 2-3 frentes.

O pharmatree resolve isso com **convenção + documentação orientadora + uma skill**.

## Estrutura de uma base pharmatree

```
<base>/                              raiz · CLAUDE.md = ORQUESTRADOR (+ AGENTS.md)
├── <repo-a>/  <repo-b>/  <repo-c>/  repos RAIZ (origem) — NUNCA tocados
└── worktrees/
    └── <type>-<slug>/              uma FRENTE (rode 2-3 em paralelo)
        ├── <repo-a>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
        ├── <repo-b>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
        └── <repo-c>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
```

### Convenção (conventional commits)

| Elemento | Padrão | Exemplo |
|---|---|---|
| Pasta da frente | `<type>-<slug>` | `feat-atendimentos-grupos` |
| Branch (mesma em todos os repos) | `<type>/<slug>` | `feat/atendimentos-grupos` |
| Subpasta do repo | nome exato do repo | `web-pharmachatbot` |
| Commit | conventional, subject-only + footer Co-Author | `feat: adiciona X` |

`type` ∈ `feat` `fix` `refactor` `chore` `docs` `test` `perf` `build` `ci`.

## Conteúdo deste repo

```
pharmatree/
├── skills/pharmatree/        ← a skill guarda-chuva (SKILL.md + 4 procedimentos)
│   └── references/           ← onde-estou · nova-frente · guard · doctor
├── templates/                ← CLAUDE.root.md (orquestrador) · CLAUDE.worktree.md
└── docs/                     ← spec de design aprovado
```

## Como aplicar a uma base

1. **Instale a skill** na base (ou globalmente). Ex., na base:
   ```bash
   mkdir -p <base>/.claude/skills
   ln -s <caminho>/pharmatree/skills/pharmatree <base>/.claude/skills/pharmatree
   ```
   (ou copie a pasta, se preferir não usar symlink.)

2. **Crie o orquestrador** na raiz da base a partir do template:
   ```bash
   cp <caminho>/pharmatree/templates/CLAUDE.root.md <base>/CLAUDE.md
   ln -sf CLAUDE.md <base>/AGENTS.md
   ```
   Preencha repos, papéis e o Mapa de frentes.

3. **Trabalhe pela skill.** Em qualquer agente, dentro da base:
   - "onde estou?" → `onde-estou`
   - "criar frente nova" → `nova-frente`
   - antes de commitar → `guard`
   - worktree quebrada → `doctor`

## Princípios

- **Git é a fonte da verdade** — repo origem e branch são re-derivados ao vivo
  (`git rev-parse --git-common-dir` / `--abbrev-ref HEAD`).
- **Repos raiz são imutáveis** — todo commit acontece em worktrees.
- **Sem artefatos que envelhecem** — só 2 níveis de doc (raiz + por-worktree),
  ambos curtos e regeneráveis pela skill.
