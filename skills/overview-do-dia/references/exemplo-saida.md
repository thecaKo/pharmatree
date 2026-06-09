# Exemplos de saída (referência de redação)

Estes são exemplos do **texto final** que o agente redige a partir do JSON de
`overview.sh`. Não são o JSON cru — são o que o usuário lê.

## Modo `inicio` (plano do dia)

```
☀️ Overview do dia — início (09:02)

🔴 Atrasados (1) — resolver primeiro
  • Corrigir bug do login (QA reprovou) — Sprint · Reprovado · Alta · venceu 08/06

🧪 Testes reprovados (1)
  • Testes do connector reprovados — Sprint · Crítica

👀 Code review pendente (1)
  • PR atendimentos-v2 aguardando review — Sprint · Crítica · prazo 12/06

🛠️ Em andamento (1) · 📋 A fazer (2)
  • Implementar dashboard outbox — Sprint · Média
  • Refinar card pharma-agent — Backlog · Baixa · hoje

Sugestão de foco: matar o item atrasado e os reprovados antes do almoço; a PR de
review desbloqueia o time.
```

## Modo `meio` (progresso / bloqueios)

```
🕐 Overview do dia — meio (14:10)

Ainda travando:
  • Testes do connector reprovados (Crítica) — continua reprovado
  • PR atendimentos-v2 — review ainda pendente

Maior urgência agora: Corrigir bug do login (atrasado, Alta).
Se já fechou algo da manhã, o próximo natural é a PR de review.
```

## Modo `fim` (fechamento)

```
🌙 Overview do dia — fim (18:05)

Ainda aberto pra amanhã:
  🔴 Corrigir bug do login (QA reprovou) — atrasado desde 08/06
  🧪 Testes do connector reprovados — Crítica
  👀 PR atendimentos-v2 — aguardando review

Atenção: 1 item atrasado e 1 teste reprovado seguem pendentes. Bom ponto de
partida pra amanhã cedo.

(A skill não guarda histórico do dia — isto é o estado atual do Monday.)
```
