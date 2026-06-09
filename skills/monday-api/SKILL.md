---
name: monday-api
description: Use when making ANY change to Monday.com (create/update/move/archive/delete items, set column values, change status/people/date, post updates or comments) or reading board/item/group data via the Monday API. The single mandatory gateway for every Monday.com operation in this base.
---

# monday-api

## Overview

**Single gateway for ALL Monday.com operations.** Toda e qualquer leitura ou
alteração no Monday (itens, colunas, status, grupos, updates/comentários) DEVE
passar por esta skill e pelo helper `monday.sh`. Isso garante uma única fonte de
token, uma única versão de API e um ponto único para auditar/confirmar operações
destrutivas.

Autenticação é por **variável de ambiente** `MONDAY_API_TOKEN` — **nunca** embuta o
token em código, prompt, ou no git.

## Regra de ouro (discipline)

- **Nenhuma chamada ao Monday fora desta skill.** Não monte `curl`/`fetch` ad-hoc
  para `api.monday.com` com outra fonte de token. Use `monday.sh`.
- **Token só via `MONDAY_API_TOKEN`.** Se não estiver definido, **pare e peça** ao
  usuário para exportá-lo — não invente, não procure token em arquivos, não
  hardcode.
- **Operações destrutivas exigem confirmação explícita do usuário** antes de rodar:
  `delete_item`, `archive_item`, `delete_group`, `delete_update`, qualquer
  `change_*` em massa. Mostre o que será alterado e espere "ok".
- Violar a letra desta regra é violar o espírito dela.

## Setup (uma vez por shell)

```bash
export MONDAY_API_TOKEN="<seu token da API do Monday>"   # Monday → Avatar → Developers → My access tokens
# opcional: export MONDAY_API_VERSION="2024-10"
```

Requer `curl` e `jq` no PATH.

## Uso

`monday.sh` recebe uma query/mutation GraphQL e (opcional) um JSON de variáveis,
e devolve a resposta JSON da API:

```bash
./monday.sh '<graphql>' '<variables-json>'
```

## Quick reference (operações comuns)

| Intenção | GraphQL |
|---|---|
| Ler um board (grupos + colunas) | `query{ boards(ids:[BOARD_ID]){ name groups{id title} columns{id title type} } }` |
| Listar itens (paginado) | `query{ boards(ids:[BOARD_ID]){ items_page(limit:50){ cursor items{id name} } } }` |
| Criar item | `mutation($b:ID!,$g:String!,$n:String!,$v:JSON!){ create_item(board_id:$b,group_id:$g,item_name:$n,column_values:$v){id} }` |
| Mudar colunas de um item | `mutation($b:ID!,$i:ID!,$v:JSON!){ change_multiple_column_values(board_id:$b,item_id:$i,column_values:$v){id} }` |
| Mover item de grupo | `mutation($i:ID!,$g:String!){ move_item_to_group(item_id:$i,group_id:$g){id} }` |
| Postar update/comentário | `mutation($i:ID!,$t:String!){ create_update(item_id:$i,body:$t){id} }` |
| Arquivar item (destrutivo) | `mutation($i:ID!){ archive_item(item_id:$i){id} }` |
| Apagar item (destrutivo) | `mutation($i:ID!){ delete_item(item_id:$i){id} }` |

Exemplo — criar item com status e data via variáveis (sem interpolar valores na query):

```bash
./monday.sh \
  'mutation($b:ID!,$g:String!,$n:String!,$v:JSON!){ create_item(board_id:$b,group_id:$g,item_name:$n,column_values:$v){id} }' \
  '{"b":"123456","g":"topics","n":"Novo card","v":"{\"status\":{\"label\":\"Working on it\"},\"date4\":{\"date\":\"2026-06-10\"}}"}'
```

> `column_values` é uma **string JSON** dentro do JSON de variáveis (note o escape).
> IDs de coluna (`status`, `date4`, …) e `group_id` vêm do board — leia o board
> primeiro se não os souber.

## Common mistakes

- **Interpolar valores direto na string da query** → quebra com aspas/acentos e
  abre injeção. Sempre passe dados via o 2º argumento (variáveis GraphQL).
- **Erros vêm com HTTP 200**: a API do Monday devolve `{"errors":[...]}` com status
  200. Sempre cheque o campo `errors` na resposta (o helper imprime o JSON cru).
- **`column_values` como objeto** em vez de string JSON → a API rejeita. Tem que ser
  string JSON escapada.
- **Rodar destrutivo sem confirmar** → pare e peça ok antes.
- **Token ausente** → `monday.sh` falha com instrução clara; exporte
  `MONDAY_API_TOKEN`, não contorne.

## Implementação

Gateway reutilizável: [`monday.sh`](./monday.sh) — lê `MONDAY_API_TOKEN`, faz POST
em `https://api.monday.com/v2`, monta `{query,variables}` com `jq` e imprime a
resposta. É o único ponto autorizado a falar com o Monday.
