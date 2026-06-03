---
name: pharmatree
description: >-
  Use ao trabalhar numa base multi-repo organizada com worktrees (estrutura
  pharmatree). Dispara quando o agente precisa SE LOCALIZAR ("onde estou", "qual
  repo/branch é esse", "retomar frente"), CRIAR uma frente nova multi-repo
  ("nova frente", "criar worktree"), VERIFICAR antes de commitar ("antes de
  commitar", "git commit", "posso commitar aqui"), CRIAR/REVISAR uma PR ("criar PR",
  "abrir PR", "abri a PR", "revisar a PR", "roda os agentes na PR"), FECHAR uma feature ("terminei a
  feature", "fim de feature", "rodar integration tests") ou REPARAR worktrees
  quebradas ("worktree prunable", "git worktree quebrado", "sincronizar mapa").
  Garante que o agente nunca commite no repo raiz nem na branch/pasta errada e que
  o fluxo de testes (unitários antes de commitar, integração ao fim da feature)
  seja respeitado.
---

# pharmatree — orquestração multi-repo com worktrees

Framework para trabalhar em **várias frentes ao mesmo tempo** sobre **múltiplos
repositórios**, usando git worktrees, sem nunca tocar nos repos raiz nem commitar
no lugar errado.

## Topologia (memorize)

```
<base>/                                 raiz: agrega os repos · CLAUDE.md = ORQUESTRADOR
├── <repo-a>/  <repo-b>/  <repo-c>/     repos RAIZ (origem) — NUNCA tocados/commitados
└── worktrees/
    └── <type>-<slug>/                  uma FRENTE (rode 2-3 em paralelo)
        ├── <repo-a>/  CLAUDE.md+AGENTS.md   worktree · branch <type>/<slug>
        ├── <repo-b>/  CLAUDE.md+AGENTS.md   worktree · branch <type>/<slug>
        └── <repo-c>/  CLAUDE.md+AGENTS.md   worktree · branch <type>/<slug>
```

## Convenção (conventional commits) — inviolável

| Elemento | Padrão | Exemplo |
|---|---|---|
| Pasta da frente | `<type>-<slug-kebab>` | `feat-atendimentos-grupos` |
| Branch (a MESMA em todos os repos da frente) | `<type>/<slug-kebab>` | `feat/atendimentos-grupos` |
| Subpasta do repo | nome **exato** do repo origem | `web-pharmachatbot` |
| Mensagem de commit | **pt-br**, conventional, **subject-only** (sem body) + footer Co-Author | `feat: adiciona X` |

`type` ∈ `feat` · `fix` · `refactor` · `chore` · `docs` · `test` · `perf` · `build` · `ci`.
Mapeamento determinístico pasta↔branch: trocar o **primeiro** `-` por `/`.

## Regras de ouro

1. **Repos raiz NUNCA recebem commit.** Todo trabalho vive em `worktrees/<frente>/<repo>/`.
2. **Uma frente = uma branch** `<type>/<slug>` atravessando seus repos.
3. **Antes de QUALQUER commit**, rode o procedimento `guard` — que inclui rodar a
   **bateria de testes unitários** (deve passar) antes de commitar.
4. **Ao fim de cada feature**, rode o procedimento `finish-feature` — que roda os
   **testes de integração** (apenas se o ambiente já estiver pronto; o agente nunca
   sobe infra por conta própria).
5. **Commits em pt-br**, conventional commits, **subject-only** (sem body) + footer
   Co-Author.
6. **A verdade vem do git ao vivo** (`git rev-parse`), nunca de um arquivo salvo.
7. **No repo `neo-api`, priorize a documentação.** Consulte a doc do repo primeiro e
   só recorra ao código-fonte **se precisar de mais contexto** — economiza tokens.

## Workflow de desenvolvimento (superpowers)

**Pré-requisito:** o plugin [superpowers](https://github.com/obra/superpowers) deve
estar instalado para Claude. O pharmatree organiza *onde* o trabalho acontece; o
superpowers organiza *como*. Use as skills do superpowers em cada fase:

| Fase | Skill superpowers |
|---|---|
| Antes de criar feature/ideia | `superpowers:brainstorming` |
| Transformar spec em plano | `superpowers:writing-plans` |
| Implementar (sempre via testes) | `superpowers:test-driven-development` |
| Bug / falha de teste / comportamento estranho | `superpowers:systematic-debugging` |
| Antes de afirmar "pronto/passa" ou commitar | `superpowers:verification-before-completion` |
| Pedir/receber code review | `superpowers:requesting-code-review` · `superpowers:receiving-code-review` |
| Após abrir a PR (review multi-agente por dimensão) | **review-pr** (`references/review-pr.md`) — complementa o code review acima |
| Fechar a branch (merge/PR/cleanup) | `superpowers:finishing-a-development-branch` |

Fluxo típico de uma frente: `brainstorming` → `writing-plans` → (por task) `TDD` /
`systematic-debugging` → `guard` (testes unitários + commit) → repetir → ao fim:
`finish-feature` (testes de integração) → `finishing-a-development-branch`.

## Roteamento — escolha o procedimento

| Intenção | Procedimento | Arquivo |
|---|---|---|
| "Onde estou? Qual repo/branch? Me perdi / retomar" | **where-am-i** | `references/where-am-i.md` |
| "Criar uma frente nova multi-repo" | **new-initiative** | `references/new-initiative.md` |
| "Vou commitar / posso commitar aqui?" | **guard** | `references/guard.md` |
| "Criar PR / abri a PR / revisar a PR / roda os agentes na PR" | **review-pr** | `references/review-pr.md` |
| "Terminei a feature / rodar integration tests" | **finish-feature** | `references/finish-feature.md` |
| "Worktree quebrada / prunable / sincronizar mapa" | **doctor** | `references/doctor.md` |

Leia o arquivo de referência correspondente e siga-o passo a passo. Em dúvida sobre
contexto, comece **sempre** por `where-am-i`.
