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

## Comandos de teste (preencher por repo)

- **Testes unitários:** `<ex.: pnpm vitest:unit>` — rodados pelo `guard` antes de cada commit.
- **Testes de integração:** `<ex.: pnpm vitest:integration>` — rodados pelo `finish-feature` ao fim da feature.
- **Ambiente de integração (health-check read-only):** `<ex.: docker ps | grep mysql-...test ; comando de ping do banco>`
  — o agente só roda integração se isto indicar ambiente pronto; nunca sobe infra.

## ⛔ Regra local

- Commit **só aqui**, na branch **`<type>/<slug>`**.
- **Não** toque no repo raiz `<repo>/` (origem) — ele é imutável.
- Antes de commitar, rode o `guard` da skill `pharmatree` (branch protegida,
  pasta==branch e **unit tests verdes** são exigidos).
- Commits em **pt-br**, conventional, **subject-only** (sem body) + footer Co-Author.
- Ao fim da feature, rode o `finish-feature` (testes de integração).
- **Se este repo for `neo-api`:** priorize a documentação — consulte a doc primeiro e
  só vá ao código-fonte **se precisar de mais contexto** (economiza tokens).

## Contexto multi-repo

Esta frente também envolve: <lista dos outros repos da frente, ou "—">.
Mapa completo e status: ver `CLAUDE.md` raiz da base (orquestrador).
