---
name: overview-do-dia
description: Use quando o usuário pedir um panorama/overview do dia de trabalho — "como está meu dia", "o que tenho pra hoje", "overview do dia", "início/meio/fim de dia", "minhas tasks", "o que falta", "code reviews pendentes", "testes reprovados". Lê (read-only) as atribuições do usuário no Monday e devolve um resumo priorizado por urgência, com ênfase conforme a hora (início = plano, meio = progresso, fim = fechamento).
---

# overview-do-dia

## Overview

Dá um **overview do dia de trabalho** do usuário a partir do Monday.com, **somente
leitura**. Mostra tasks atribuídas, code reviews pendentes e testes reprovados,
ordenados por urgência (prazo + prioridade + tipo de status). Pensada para rodar no
**início, meio e fim** do dia.

- **Fonte única:** Monday via o gateway `monday.sh` da skill `monday-api`. Nunca
  monte chamadas à API direto — `overview.sh` já chama o `monday.sh` por baixo.
- **Read-only:** esta skill **nunca** altera nada no Monday. Se o usuário pedir uma
  ação (mover card, comentar etc.), isso é outra coisa — use a skill `monday-api`
  com confirmação, não esta.
- **Idioma:** todo o resumo é em português (regra da base).

## Pré-requisitos

- `MONDAY_API_TOKEN` disponível para o `monday.sh`. O token fica salvo localmente
  fora do git em `~/.config/monday/token`; passe-o por chamada com
  `export MONDAY_API_TOKEN="$(cat ~/.config/monday/token)"`. Se o arquivo não
  existir nem houver env, **pare e peça** o token — não procure em outros arquivos.
- `config.json` já vem calibrado para o board **"Desenvolvimento 💨"**
  (`18391375493`), usuário **"Carlos Felix - Dev 3"**, com os IDs de coluna reais
  (Etapa, Criticidade, Resp., Par, Conclusão). Para outro board, ajuste
  `board_ids`, `columns.*` (IDs das colunas) e `status_categories`.

## Procedimento

1. **Descubra o modo.** Se o usuário disse explicitamente (início/manhã,
   meio/tarde, fim/encerrar), passe como argumento. Senão, deixe o script inferir
   pela hora.

2. **Rode o coletor** (a partir da pasta da skill, com o token no ambiente):
   ```bash
   export MONDAY_API_TOKEN="$(cat ~/.config/monday/token)"
   ./overview.sh            # infere o modo pela hora
   ./overview.sh inicio     # ou: meio | fim
   ```
   Ele resolve seu usuário pelo nome, varre os `board_ids` (com paginação),
   recolhe itens em que você é **Resp.** ou **Par** (cada item traz `role` e
   `group`), e imprime um **JSON** com `mode`, `counts` e `buckets` (`atrasados`,
   `teste_reprovado`, `code_review`, `em_andamento`, `a_fazer`), cada bucket já
   ordenado por `urgency_score` (desc). Itens onde você é par vêm marcados
   `role:"par"` — sinalize isso no texto (você não é o dono principal).

3. **Trate erros comuns** sem contornar a regra:
   - Token ausente → peça `export MONDAY_API_TOKEN=...`.
   - `board_ids` ainda com placeholder → peça os IDs e ajude a preencher o
     `config.json`.
   - Usuário não encontrado → confirme o `user_name` exato no Monday.

4. **Redija o overview** a partir do JSON, no tom do **modo**:

   - **inicio (plano do dia):** comece pelos `atrasados`, depois `teste_reprovado`
     e `code_review` (desbloqueiam outros), depois o que atacar em `em_andamento` /
     `a_fazer`. Sugira um foco para a manhã. Curto e acionável.
   - **meio (progresso/bloqueios):** destaque o que provavelmente já avançou e o que
     está travando — reprovados e reviews que continuam pendentes. Aponte o próximo
     item de maior `urgency_score`.
   - **fim (fechamento):** o que ainda está aberto e precisa de atenção amanhã;
     liste explicitamente reprovados/reviews ainda pendentes (o que "voltou pra
     você"). Sem inventar o que foi concluído — a skill não guarda histórico.

   Sempre: itens `overdue` em destaque no topo; cite `name`, `board`, `status`,
   prioridade e prazo. Não despeje o JSON cru — escreva um resumo legível. Veja
   [`references/exemplo-saida.md`](./references/exemplo-saida.md).

## Configuração da classificação

`config.json` controla o mapeamento (sem mexer no código):

- `columns`: IDs **explícitos** das colunas do board — `people_resp` e `people_par`
  (colunas de pessoa), `status` (coluna de etapa do fluxo, ex.: "Etapa"),
  `priority` (ex.: "Criticidade") e `date` (ex.: "Conclusão").
- `status_categories`: quais **labels** de Etapa caem em cada categoria
  (`teste_reprovado`, `code_review`, `em_andamento`, `a_fazer`, `concluido`).
  `concluido` é omitido do overview.
- `priority_order`: ordem da Criticidade (do mais para o menos urgente):
  `Urgente > Alta > Média > Baixa`.
- **Nota sobre prazo:** neste board a coluna de data é "Conclusão" (data de
  *fechamento*), que itens ativos quase sempre têm vazia — então a urgência é, na
  prática, dirigida por **categoria de status + Criticidade**, e `atrasados`
  raramente terá itens. É esperado.

## Teste

A lógica de classificação/urgência é testável sem rede:
```bash
./test-overview.sh
```
Usa [`references/fixture-items.json`](./references/fixture-items.json) e
`overview.sh --classify` (lê JSON cru do stdin, sem chamar o Monday).

## Regra de ouro

Read-only e via `monday.sh`. Se algo exigir escrever no Monday, **não** faça aqui —
isso é trabalho da skill `monday-api`, com confirmação explícita do usuário.
