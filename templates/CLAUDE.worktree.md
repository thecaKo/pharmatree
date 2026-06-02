<!--
  TEMPLATE — CLAUDE.md por-repo-worktree (pharmatree).
  Gerado pela skill (procedimento nova-frente) em worktrees/<frente>/<repo>/CLAUDE.md.
  Crie AGENTS.md como symlink ao lado:  ln -sf CLAUDE.md AGENTS.md
-->

# <repo> · frente <type>-<slug>

> **Você está em:** frente **`<type>-<slug>`** · repo origem **`<repo>`** · branch
> **`<type>/<slug>`** · papel **<web | api | neo-api | …>**.

## Objetivo da frente

<1-2 linhas: o que esta frente entrega, no contexto deste repo.>

## ⛔ Regra local

- Commit **só aqui**, na branch **`<type>/<slug>`**.
- **Não** toque no repo raiz `<repo>/` (origem) — ele é imutável.
- Antes de commitar, rode o `guard` da skill `pharmatree` (branch protegida e
  pasta==branch são bloqueadas).

## Contexto multi-repo

Esta frente também envolve: <lista dos outros repos da frente, ou "—">.
Mapa completo e status: ver `CLAUDE.md` raiz da base (orquestrador).
