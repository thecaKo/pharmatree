---
name: pharmatree
description: >-
  Use ao trabalhar numa base multi-repo organizada com worktrees (estrutura
  pharmatree). Dispara quando o agente precisa SE LOCALIZAR ("onde estou", "qual
  repo/branch é esse", "retomar frente"), CRIAR uma frente nova multi-repo
  ("nova frente", "criar worktree"), VERIFICAR antes de commitar ("antes de
  commitar", "git commit", "posso commitar aqui") ou REPARAR worktrees quebradas
  ("worktree prunable", "git worktree quebrado", "sincronizar mapa"). Garante que
  o agente nunca commite no repo raiz nem na branch/pasta errada.
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
| Mensagem de commit | conventional, **subject-only** + footer Co-Author | `feat: adiciona X` |

`type` ∈ `feat` · `fix` · `refactor` · `chore` · `docs` · `test` · `perf` · `build` · `ci`.
Mapeamento determinístico pasta↔branch: trocar o **primeiro** `-` por `/`.

## Regras de ouro

1. **Repos raiz NUNCA recebem commit.** Todo trabalho vive em `worktrees/<frente>/<repo>/`.
2. **Uma frente = uma branch** `<type>/<slug>` atravessando seus repos.
3. **Antes de QUALQUER commit**, rode o procedimento `guard` (abaixo).
4. **A verdade vem do git ao vivo** (`git rev-parse`), nunca de um arquivo salvo.

## Roteamento — escolha o procedimento

| Intenção | Procedimento | Arquivo |
|---|---|---|
| "Onde estou? Qual repo/branch? Me perdi / retomar" | **onde-estou** | `references/onde-estou.md` |
| "Criar uma frente nova multi-repo" | **nova-frente** | `references/nova-frente.md` |
| "Vou commitar / posso commitar aqui?" | **guard** | `references/guard.md` |
| "Worktree quebrada / prunable / sincronizar mapa" | **doctor** | `references/doctor.md` |

Leia o arquivo de referência correspondente e siga-o passo a passo. Em dúvida sobre
contexto, comece **sempre** por `onde-estou`.
