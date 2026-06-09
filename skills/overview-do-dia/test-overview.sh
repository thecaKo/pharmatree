#!/usr/bin/env bash
#
# test-overview.sh — testa a classificação de overview.sh com um fixture (sem rede).
# Roda: ./test-overview.sh
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE="$SCRIPT_DIR/references/fixture-items.json"

OUT="$("$SCRIPT_DIR/overview.sh" --classify < "$FIXTURE")"

fail=0
check() { # $1 descrição  $2 jq-filter (deve dar true)
  if printf '%s' "$OUT" | jq -e "$2" >/dev/null; then
    echo "  ok   - $1"
  else
    echo "  FAIL - $1"; fail=1
  fi
}

echo "test-overview (classificação):"
check "total = 6 (concluído excluído)"          '.counts.total == 6'
check "1 atrasado"                              '.counts.atrasados == 1'
check "atrasado é o A (QA reprovou, vencido)"   '.buckets.atrasados | map(.id) == ["A"]'
check "teste_reprovado = [F]"                   '.buckets.teste_reprovado | map(.id) == ["F"]'
check "code_review = [B]"                       '.buckets.code_review | map(.id) == ["B"]'
check "em_andamento = [C]"                      '.buckets.em_andamento | map(.id) == ["C"]'
check "a_fazer ordenado = [D, G]"               '.buckets.a_fazer | map(.id) == ["D","G"]'
check "status desconhecido cai em a_fazer"      '.buckets.a_fazer | map(.id) | index("G") != null'
check "concluído (E) não aparece"               '[.buckets[][].id] | index("E") == null'
check "A marcado overdue"                       '.buckets.atrasados[0].overdue == true'

if [ "$fail" -ne 0 ]; then echo "FALHOU"; exit 1; fi
echo "todos os testes passaram"
