#!/usr/bin/env bash
#
# overview.sh — coletor + classificador do "overview do dia" (skill: overview-do-dia).
# READ-ONLY. Toda leitura do Monday passa pelo gateway monday.sh (skill monday-api).
#
# Uso:
#   ./overview.sh [inicio|meio|fim]     # coleta do Monday e emite JSON classificado
#   ./overview.sh --classify            # lê JSON cru de stdin e só classifica (sem rede)
#
# Sem argumento de modo, infere pela hora local: <12h=inicio, 12-17h=meio, >=17h=fim.
# Config: $OVERVIEW_CONFIG ou ./config.json (board_ids, nome do usuário, IDs de coluna, labels).
# Token: env MONDAY_API_TOKEN (exigido pelo monday.sh).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONDAY="${MONDAY_SH:-$SCRIPT_DIR/../monday-api/monday.sh}"
CONFIG="${OVERVIEW_CONFIG:-$SCRIPT_DIR/config.json}"

command -v jq >/dev/null 2>&1 || { echo "overview.sh: requer 'jq' no PATH" >&2; exit 127; }
[ -f "$CONFIG" ] || { echo "overview.sh: config não encontrada: $CONFIG" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Núcleo de classificação (jq puro). Recebe no stdin:
#   { generated_at, today, mode, user, items:[ {id,name,board,group,role,status,priority,due_date} ] }
# Emite o JSON final com buckets ordenados por urgência. Campos extras (role, group)
# passam adiante intactos.
# ---------------------------------------------------------------------------
read -r -d '' CLASSIFY_JQ <<'JQ' || true
def days_between($a; $b):
  (($b | strptime("%Y-%m-%d") | mktime) - ($a | strptime("%Y-%m-%d") | mktime)) / 86400 | floor;
def catweight($k):
  {teste_reprovado:100, code_review:80, em_andamento:40, a_fazer:20, concluido:0}[$k] // 20;

($cfg[0]) as $c
| .today as $today
| ($c.priority_order | length) as $plen
| [ .items[]
    | . as $it
    | ( $c.status_categories | to_entries
        | map(select(.value | index($it.status)))
        | (.[0].key // "a_fazer") ) as $cat
    | select($cat != "concluido")
    | ( $c.priority_order | index($it.priority) ) as $pidx
    | ( if $pidx == null then 0 else ($plen - $pidx) * 10 end ) as $pw
    | ( if ($it.due_date != null and $it.due_date != "")
        then days_between($today; $it.due_date) else null end ) as $dd
    | ( $dd != null and $dd < 0 ) as $overdue
    | ( if $dd == null then 0
        elif $dd < 0 then 60
        elif $dd <= 7 then (30 - ($dd * 3))
        else 2 end ) as $dw
    | $it + {
        category: $cat,
        priority: ($it.priority // "—"),
        priority_weight: $pw,
        overdue: $overdue,
        days_until_due: $dd,
        urgency_score: (catweight($cat) + $pw + $dw)
      }
  ] as $cls
| {
    generated_at: .generated_at,
    mode: .mode,
    user: .user,
    counts: {
      total: ($cls | length),
      atrasados: ([ $cls[] | select(.overdue) ] | length)
    },
    buckets: {
      atrasados:       ([ $cls[] | select(.overdue) ]                                            | sort_by(-.urgency_score)),
      teste_reprovado: ([ $cls[] | select(.overdue|not) | select(.category=="teste_reprovado") ] | sort_by(-.urgency_score)),
      code_review:     ([ $cls[] | select(.overdue|not) | select(.category=="code_review") ]     | sort_by(-.urgency_score)),
      em_andamento:    ([ $cls[] | select(.overdue|not) | select(.category=="em_andamento") ]    | sort_by(-.urgency_score)),
      a_fazer:         ([ $cls[] | select(.overdue|not) | select(.category=="a_fazer") ]         | sort_by(-.urgency_score))
    }
  }
JQ

run_classify() { jq --slurpfile cfg "$CONFIG" "$CLASSIFY_JQ"; }

# ---------------------------------------------------------------------------
# Parse de argumentos
# ---------------------------------------------------------------------------
MODE=""
CLASSIFY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --classify) CLASSIFY=1 ;;
    inicio|meio|fim) MODE="$1" ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "overview.sh: argumento inválido '$1' (use inicio|meio|fim ou --classify)" >&2; exit 2 ;;
  esac
  shift
done

# Modo --classify: só roda o núcleo sobre o stdin (usado nos testes).
if [ "$CLASSIFY" -eq 1 ]; then
  run_classify
  exit 0
fi

# ---------------------------------------------------------------------------
# Coleta ao vivo (read-only via monday.sh)
# ---------------------------------------------------------------------------
TODAY="$(date +%F)"
GENERATED_AT="$(date --iso-8601=seconds 2>/dev/null || date +%FT%T%z)"

if [ -z "$MODE" ]; then
  H="$(date +%H)"; H="${H#0}"
  if   [ "${H:-0}" -lt 12 ]; then MODE="inicio"
  elif [ "${H:-0}" -lt 17 ]; then MODE="meio"
  else MODE="fim"; fi
fi

[ -x "$MONDAY" ] || { echo "overview.sh: gateway monday.sh não encontrado/executável: $MONDAY" >&2; exit 1; }

# IDs de coluna (do config).
C_RESP="$(jq -r '.columns.people_resp // empty' "$CONFIG")"
C_PAR="$(jq -r '.columns.people_par // empty' "$CONFIG")"
C_STATUS="$(jq -r '.columns.status' "$CONFIG")"
C_PRI="$(jq -r '.columns.priority // empty' "$CONFIG")"
C_DATE="$(jq -r '.columns.date // empty' "$CONFIG")"
COLS="$(jq -c '[.columns.people_resp, .columns.people_par, .columns.status, .columns.priority, .columns.date] | map(select(. != null and . != ""))' "$CONFIG")"

# 1) Resolve o usuário pelo nome (exato; cai p/ contains se não houver exato).
USER_NAME="$(jq -r '.user_name' "$CONFIG")"
USERS_JSON="$("$MONDAY" 'query{ users(limit:500){ id name } }')"
USER="$(printf '%s' "$USERS_JSON" | jq --arg n "$USER_NAME" '
  .data.users
  | ( ( map(select(.name == $n)) | .[0] )
      // ( map(select(.name | ascii_downcase | contains($n | ascii_downcase))) | .[0] )
      // null )
  | if . == null then null else {id: (.id|tostring), name: .name} end')"
if [ "$USER" = "null" ] || [ -z "$USER" ]; then
  echo "overview.sh: usuário '$USER_NAME' não encontrado no Monday." >&2; exit 1
fi
USER_ID="$(printf '%s' "$USER" | jq -r '.id')"

# Mapeia uma página de itens (stdin = array de items) para a forma crua, filtrando
# apenas itens em que o USER_ID aparece em Resp. ou Par. Marca o papel (resp/par).
map_items() { # $1 board_name
  jq --arg bname "$1" --arg uid "$USER_ID" \
     --arg c_resp "$C_RESP" --arg c_par "$C_PAR" \
     --arg c_status "$C_STATUS" --arg c_pri "$C_PRI" --arg c_date "$C_DATE" '
    def cv($id): ( [ .column_values[] | select(.id == $id) ] | first );
    def has_uid($col): ( [ ((($col.persons_and_teams) // [])[]) | .id | tostring ] | index($uid) ) != null;
    [ .[]
      | (cv($c_resp)) as $resp
      | (cv($c_par))  as $par
      | (has_uid($resp)) as $is_resp
      | (has_uid($par))  as $is_par
      | select($is_resp or $is_par)
      | (cv($c_status)) as $st
      | (cv($c_pri))    as $pr
      | (cv($c_date))   as $dt
      | {
          id: (.id|tostring),
          name: .name,
          board: $bname,
          group: (.group.title // null),
          role: (if $is_resp then "resp" else "par" end),
          status:   ($st.label // $st.text // null),
          priority: ($pr.label // $pr.text // null),
          due_date: ( $dt.date // ( ($dt.text // "") | [ scan("[0-9]{4}-[0-9]{2}-[0-9]{2}") ] | last ) )
        }
    ]'
}

BOARD_QUERY='query($b:[ID!],$cols:[String!]){ boards(ids:$b){ id name items_page(limit:300){ cursor items{ id name group{ title } column_values(ids:$cols){ id text type ... on PeopleValue{ persons_and_teams{ id } } ... on DateValue{ date } ... on StatusValue{ label } } } } } }'
NEXT_QUERY='query($c:String!,$cols:[String!]){ next_items_page(limit:300,cursor:$c){ cursor items{ id name group{ title } column_values(ids:$cols){ id text type ... on PeopleValue{ persons_and_teams{ id } } ... on DateValue{ date } ... on StatusValue{ label } } } } }'

ITEMS_ACC="[]"
while IFS= read -r BID; do
  [ -n "$BID" ] || continue
  if [ "$BID" = "REPLACE_COM_SEU_BOARD_ID" ]; then
    echo "overview.sh: preencha board_ids em $CONFIG (ainda está com o placeholder)." >&2
    exit 1
  fi
  RESP="$("$MONDAY" "$BOARD_QUERY" "$(jq -n --arg b "$BID" --argjson cols "$COLS" '{b:[$b], cols:$cols}')")"
  BNAME="$(printf '%s' "$RESP" | jq -r '.data.boards[0].name // "?"')"
  PAGE="$(printf '%s' "$RESP" | jq '.data.boards[0].items_page.items // []')"
  MAPPED="$(printf '%s' "$PAGE" | map_items "$BNAME")"
  ITEMS_ACC="$(jq -s 'add' <(printf '%s' "$ITEMS_ACC") <(printf '%s' "$MAPPED"))"
  CURSOR="$(printf '%s' "$RESP" | jq -r '.data.boards[0].items_page.cursor // empty')"
  while [ -n "$CURSOR" ]; do
    RESP="$("$MONDAY" "$NEXT_QUERY" "$(jq -n --arg c "$CURSOR" --argjson cols "$COLS" '{c:$c, cols:$cols}')")"
    PAGE="$(printf '%s' "$RESP" | jq '.data.next_items_page.items // []')"
    MAPPED="$(printf '%s' "$PAGE" | map_items "$BNAME")"
    ITEMS_ACC="$(jq -s 'add' <(printf '%s' "$ITEMS_ACC") <(printf '%s' "$MAPPED"))"
    CURSOR="$(printf '%s' "$RESP" | jq -r '.data.next_items_page.cursor // empty')"
  done
done < <(jq -r '.board_ids[]' "$CONFIG")

# Monta o JSON cru e classifica.
jq -n \
  --arg ga "$GENERATED_AT" --arg today "$TODAY" --arg mode "$MODE" \
  --argjson user "$USER" --argjson items "$ITEMS_ACC" \
  '{generated_at:$ga, today:$today, mode:$mode, user:$user, items:$items}' \
  | run_classify
