# pharmatree

A lightweight framework to **orchestrate work across multiple repositories at the
same time** using git worktrees, built for AI agents (Claude / Codex / Cursor). No
shell scripts, no git hooks, no runtime: the intelligence lives in a **skill**, and
the source of truth is always **live git**.

## Quickstart

### Setup (once, per base)

1. **Install superpowers** for Claude (prerequisite — the development workflow).
2. **Install the skill** in your base:
   ```bash
   mkdir -p <base>/.claude/skills
   ln -s <path>/pharmatree/skills/pharmatree <base>/.claude/skills/pharmatree
   ```
3. **Create the orchestrator** at the base root:
   ```bash
   cp <path>/pharmatree/templates/CLAUDE.root.md <base>/CLAUDE.md
   ln -sf CLAUDE.md <base>/AGENTS.md
   ```
   Fill in repos, roles, and the Active Initiatives map.
4. **Restart** your Claude Code session so the skill becomes invocable.
5. Type **`/pharmatree`** (or just ask in natural language) — you're ready.

### Cheatsheet — what you say → what happens

| You say… | Procedure | What happens |
|---|---|---|
| "create initiative `feat relatorios-saldo` in repos web, neo-api" | `new-initiative` | Creates `worktrees/feat-relatorios-saldo/{web,neo-api}` on branch `feat/relatorios-saldo` + generates each `CLAUDE.md`/`AGENTS.md` + updates the map |
| "where am I?" / "I'm lost" / "resume" | `where-am-i` | Reports current initiative, origin repo, branch, goal + other active initiatives |
| "can I commit?" / "commit this" | `guard` | Checks folder==branch, blocks protected branches, **runs unit tests**, then commits (pt-br, conventional, subject-only) |
| "I finished the feature" | `finish-feature` | Probes if the test env is up; if so runs integration tests; if not, lists what to start (never provisions infra) |
| "fix the worktrees" / "prunable" | `doctor` | `git worktree repair` + regenerates the Active Initiatives map |

### Typical feature lifecycle

```
brainstorming → writing-plans          (superpowers — the "how")
  → /pharmatree new-initiative          (creates worktrees + branch)
  → implement via TDD                   (superpowers)
  → /pharmatree guard   (unit tests + commit)  ⟲ repeat per task
  → /pharmatree finish-feature          (integration tests)
  → finishing-a-development-branch       (merge / PR)
```

## Why

When a single line of work spans 3+ repositories, it's easy to:

- commit to the wrong repo (the origin instead of the worktree);
- lose track of which repo/branch you're in;
- accumulate `prunable` worktrees (stale paths);
- spin up new lines of work inconsistently;
- get lost when juggling 2-3 parallel efforts.

pharmatree solves this with **convention + guiding documentation + one skill**.

## Prerequisite: superpowers

pharmatree wires in the [superpowers](https://github.com/obra/superpowers) plugin for
Claude. pharmatree decides *where* work happens (which repo/worktree/branch);
superpowers decides *how* it happens (brainstorming → planning → TDD → verification →
finishing a branch). Install superpowers for Claude before using pharmatree.

## Workflow rules

- **Commits in pt-br**, conventional commits, **subject-only** (no body) + Co-Author footer.
- **Unit tests run before every commit** (enforced by the `guard` procedure; must pass).
- **Integration tests run at the end of each feature** (`finish-feature` procedure) —
  only if the test environment is already up. The agent **never provisions infra**
  (docker/migrations/seeds): if the env isn't ready, it reports what's missing and stops.

## Layout of a pharmatree base

```
<base>/                              root · CLAUDE.md = ORCHESTRATOR (+ AGENTS.md)
├── <repo-a>/  <repo-b>/  <repo-c>/  ROOT repos (origin) — NEVER touched
└── worktrees/
    └── <type>-<slug>/              one INITIATIVE (run 2-3 in parallel)
        ├── <repo-a>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
        ├── <repo-b>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
        └── <repo-c>/  CLAUDE.md + AGENTS.md   branch <type>/<slug>
```

### Convention (conventional commits)

| Element | Pattern | Example |
|---|---|---|
| Initiative folder | `<type>-<slug>` | `feat-atendimentos-grupos` |
| Branch (same across every repo) | `<type>/<slug>` | `feat/atendimentos-grupos` |
| Repo subfolder | exact repo name | `web-pharmachatbot` |
| Commit | conventional, subject-only + Co-Author footer | `feat: add X` |

`type` ∈ `feat` `fix` `refactor` `chore` `docs` `test` `perf` `build` `ci`.
Deterministic folder↔branch mapping: replace the **first** `-` with `/`.

## What's in this repo

```
pharmatree/
├── skills/pharmatree/        ← the umbrella skill (SKILL.md + 4 procedures)
│   └── references/           ← where-am-i · new-initiative · guard · finish-feature · doctor
├── templates/                ← CLAUDE.root.md (orchestrator) · CLAUDE.worktree.md
└── docs/                     ← approved design spec
```

## How to apply it to a base

1. **Install the skill** in the base (or globally). For example, in the base:
   ```bash
   mkdir -p <base>/.claude/skills
   ln -s <path>/pharmatree/skills/pharmatree <base>/.claude/skills/pharmatree
   ```
   (or copy the folder if you'd rather not use a symlink.)

2. **Create the orchestrator** at the base root from the template:
   ```bash
   cp <path>/pharmatree/templates/CLAUDE.root.md <base>/CLAUDE.md
   ln -sf CLAUDE.md <base>/AGENTS.md
   ```
   Fill in the repos, their roles, and the Active Initiatives map.

3. **Work through the skill.** In any agent, inside the base:
   - "where am I?" → `where-am-i`
   - "start a new initiative" → `new-initiative`
   - before committing → `guard`
   - finished a feature → `finish-feature`
   - broken worktree → `doctor`

## Skill procedures

| You ask | Procedure | What it does |
|---|---|---|
| "where am I / resume" | `where-am-i` | Derives repo/branch/initiative live and reports it |
| "create a new initiative" | `new-initiative` | Creates worktrees + branches on the convention, generates docs |
| "I'm about to commit" | `guard` | Pre-commit checklist (folder==branch, blocks protected branches, runs unit tests) |
| "finished a feature" | `finish-feature` | Runs integration tests if the env is ready; never provisions infra |
| "broken worktree / prunable" | `doctor` | Repairs prunable worktrees and regenerates the map |

## Principles

- **Git is the source of truth** — origin repo and branch are re-derived live
  (`git rev-parse --git-common-dir` / `--abbrev-ref HEAD`).
- **Root repos are immutable** — every commit happens inside a worktree.
- **No artifacts that go stale** — only 2 doc levels (root + per-worktree), both
  short and regenerable by the skill.
