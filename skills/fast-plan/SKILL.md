---
name: fast-plan
description: Use quando houver spec/design aprovado e for preciso criar o plano de implementação de uma feature multi-task nesta base — substitui superpowers:writing-plans aqui. Gatilhos: "criar plano", "plano de implementação", "tasks.md", handoff do brainstorming.
---

# fast-plan

## Visão geral

O plano é um **contrato de execução** (estilo `tasks.md` do spec-kit), não um
rascunho do código. Quem escreve código é o subagente, via TDD, na execução; o
plano diz **o que**, **onde** e **como verificar** — nunca o código pronto.

**Anuncie:** "Usando fast-plan para criar o plano de implementação."

**Salvar em:** `sdd/plans/YYYY-MM-DD-<feature>-tasks.md` (no hub pharmatree —
`docs/` é repo clonado, gitignored).

## Estrutura do documento

1. **Header** — Goal (1 frase), Arquitetura (2–3 frases), Stack, link do spec.
2. **Context Pack** — escrito UMA vez; a fast-exec injeta verbatim em cada
   subagente para ninguém re-explorar o repo:
   - Comandos exatos de teste/lint/build (por repo, se multi-repo).
   - Convenções aplicáveis (padrões do código, regras do CLAUDE.md/design.md).
   - Mapa dos arquivos tocados — 1 linha por arquivo dizendo o papel atual dele.
3. **Tasks** agrupadas por camada de dependência (L1 → L2 → …).

## Formato de task

```markdown
### T3 [P] [fast] — Validador de payload  (camada L2, depende: T1)
**Arquivos:** Create: src/validators/payload.ts · Test: tests/validators/payload.test.ts
**Aceitação:** aceita payload com X; rejeita Y com erro Z
**Testes:** casos esperados, nomeados (sem o código deles)
**Design:** só quando houver decisão não-óbvia — aí sim com snippet
```

## Regras

| Regra | Detalhe |
|---|---|
| Camadas | Toda task declara camada e dependências; camadas formam DAG (sem ciclo) |
| Intra-camada | **Proibido depender de task da MESMA camada** — se T depende de T', T vai para a camada seguinte. Tasks da mesma camada são sempre mutuamente independentes |
| `[P]` | Paralelizável: arquivos **disjuntos** de todas as outras `[P]` da mesma camada |
| Tier | `[fast]` = mecânica (1–2 arquivos, spec completa) → modelo rápido; `[opus]` = integração/julgamento/multi-arquivo → Opus |
| Tamanho | Task executável em ≤ ~30 min por um subagente; maior que isso, quebre |
| Aceitação | Verificável por teste ou comando — nunca "tratar erros adequadamente" |

## Proibições

- **Código completo nos steps** (inversão do writing-plans): código aparece só
  em **Design**, quando a decisão não for óbvia para um dev competente.
- Placeholders: "TBD", "TODO", "similar à task N", aceitação vaga.
- `[P]` em duas tasks da mesma camada que tocam o mesmo arquivo.
- Referenciar tipo/função que nenhuma task define.

## Self-review (antes de entregar)

1. **Cobertura:** cada requisito do spec aponta para uma task? Liste lacunas.
2. **Disjunção:** as `[P]` de cada camada têm arquivos disjuntos?
3. **DAG:** dependências respeitam as camadas (nada depende de camada posterior
   **nem da mesma camada** — dependência intra-camada = task na camada errada)?
4. **Tiers:** alguma `[fast]` exige julgamento ou toca 3+ arquivos? Promova a `[opus]`.
5. **Verificabilidade:** toda aceitação tem teste/comando associado?

Corrija inline e siga.

## Handoff

"Plano salvo em `sdd/plans/<arquivo>`. Executar com a skill **fast-exec**."
Não ofereça executing-plans nem subagent-driven-development.
