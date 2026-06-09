#!/usr/bin/env bash
#
# monday.sh — gateway ÚNICO para a API do Monday.com (skill: monday-api).
# Toda chamada ao Monday passa por aqui. Token só via env MONDAY_API_TOKEN.
#
# Uso:
#   ./monday.sh '<graphql query|mutation>' '[variables-json]'
#
# Ex.:
#   ./monday.sh 'query{ boards(ids:[123]){ name } }'
#   ./monday.sh 'mutation($n:String!){ create_item(board_id:123,item_name:$n){id} }' '{"n":"oi"}'
#
set -euo pipefail

: "${MONDAY_API_TOKEN:?Defina o token antes de usar:  export MONDAY_API_TOKEN=...  (Monday > Developers > My access tokens)}"

API_URL="https://api.monday.com/v2"
API_VERSION="${MONDAY_API_VERSION:-2024-10}"

QUERY="${1:?uso: monday.sh '<graphql>' '[variables-json]'}"
if [ "$#" -ge 2 ] && [ -n "$2" ]; then VARIABLES="$2"; else VARIABLES='{}'; fi

command -v jq   >/dev/null 2>&1 || { echo "monday.sh: requer 'jq' no PATH" >&2; exit 127; }
command -v curl >/dev/null 2>&1 || { echo "monday.sh: requer 'curl' no PATH" >&2; exit 127; }

# Monta {query, variables} de forma segura (sem interpolar valores na query).
PAYLOAD="$(jq -n --arg q "$QUERY" --argjson v "$VARIABLES" '{query:$q, variables:$v}')"

RESPONSE="$(
  curl -sS -X POST "$API_URL" \
    -H "Authorization: $MONDAY_API_TOKEN" \
    -H "Content-Type: application/json" \
    -H "API-Version: $API_VERSION" \
    --data "$PAYLOAD"
)"

echo "$RESPONSE" | jq .

# A API do Monday devolve erros com HTTP 200 no campo "errors": falhe se houver.
if echo "$RESPONSE" | jq -e '.errors // empty | length > 0' >/dev/null 2>&1; then
  echo "monday.sh: a API retornou erros (veja acima)." >&2
  exit 1
fi
