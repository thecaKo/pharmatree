---
name: fast-exec
description: Use quando houver um plano tasks.md (gerado pelo fast-plan) pronto para implementar — substitui superpowers:subagent-driven-development e superpowers:executing-plans nesta base. Gatilhos: "executa o plano", "implementa o plano", "roda as tasks", plano salvo em sdd/plans/.
---

# fast-exec

## Visão geral

Executa o plano por **camadas de dependência**, com subagentes paralelos para
tasks `[P]` e **um review por camada**. O `tasks.md` é o **contrato**: não
replaneje, não reordene, não invente tasks. Lacuna grave no plano → pare e
pergunte ao usuário.

**Anuncie:** "Usando fast-exec para executar o plano."

**Execução contínua:** não pause entre tasks/camadas para pedir confirmação.
Pare apenas por BLOCKED não resolvível, ambiguidade real ou fim do plano.

## Protocolo

1. **Worktree:** confirme que está na worktree da frente (regra helix — nunca
   implementar em repo raiz).
2. **Carga única:** leia o plano UMA vez; extraia Context Pack e todas as tasks
   com texto completo; valide a disjunção de arquivos das `[P]` por camada
   (sobreposição → trate como sequencial e avise); crie TodoWrite.
3. **Por camada (L1 → L2 → …):**
   - Dispare todas as `[P]` da camada **em paralelo** (um Agent call por task,
     na mesma mensagem). Tasks sem `[P]` rodam em série.
   - Modelo pelo tier: `[fast]` → modelo rápido (sonnet); `[opus]` → opus.
   - Prompt de cada implementador: texto completo da task + Context Pack +
     instruções abaixo. **Nunca** mande o subagente ler o plano.
4. **Commits do controlador:** subagentes NÃO commitam. Ao fim da camada, o
   controlador faz **um commit por task** (arquivos disjuntos permitem staging
   limpo), mensagens convencionais.
5. **Gate da camada:** rode a suíte de testes relevante; depois UM review
   (subagente **Opus**) sobre o diff da camada cobrindo spec-compliance +
   qualidade. Reprovou → subagente de fix (mesmo contexto da task) → re-review.
   Só avance com gate verde.
6. **Fim do plano:** suíte completa + `superpowers:finishing-a-development-branch`.

**Override:** se o usuário pedir (ex.: código sensível), troque o gate por
review por task — mesmo formato, escopo menor.

## Prompt do implementador (resumo obrigatório)

- Contexto: onde a task se encaixa (1–2 frases) + Context Pack verbatim.
- Task completa (arquivos, aceitação, testes, design).
- **TDD obrigatório** (superpowers:test-driven-development): teste falhando →
  implementação mínima → verde.
- **NÃO commitar, NÃO tocar arquivos fora da lista da task.**
- Reportar ao final: `DONE` | `DONE_WITH_CONCERNS` | `NEEDS_CONTEXT` | `BLOCKED`
  + resumo do que fez e resultado dos testes.

## Tratamento de status

| Status | Ação |
|---|---|
| DONE | Segue para commit/gate da camada |
| DONE_WITH_CONCERNS | Ler concerns; correção/escopo → resolver antes do gate; observação → anotar |
| NEEDS_CONTEXT | Fornecer o contexto faltante e re-dispachar |
| BLOCKED | Escalar modelo (`fast`→`opus`), quebrar a task, ou parar e perguntar. Nunca re-dispachar igual |

## Red flags — pare e corrija

- Subagente commitando ou editando arquivo fora da task.
- `[P]` disparadas com arquivos sobrepostos.
- Avançar de camada com review reprovado ou testes vermelhos.
- Replanejar/reescrever tasks em vez de perguntar.
- Implementar no repo raiz ou fora da worktree da frente.
- Mandar subagente ler o plano em vez de fornecer o texto.

## Escala

Plano com 15+ tasks ou camadas muito largas: considere orquestrar a execução
com o **Workflow tool** do Claude Code (`pipeline()`/`parallel()`, worktree
isolation) — opcional, mesmo contrato e mesmos gates.
