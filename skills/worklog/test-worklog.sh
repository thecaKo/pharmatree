#!/usr/bin/env bash
# test-worklog.sh — valida a IO mecânica do worklog.sh SEM tocar no Monday/git real.
# Cria uma vault temporária + um config temporário e exercita ensure-daily.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

VAULT="$TMP/vault"
mkdir -p "$VAULT"

# config temporário apontando pra vault temporária
CFG="$TMP/config.json"
cat > "$CFG" <<EOF
{
  "vault_path": "$VAULT",
  "git_author": "ninguem",
  "overview_script": "../overview-do-dia/overview.sh",
  "repos": []
}
EOF

# roda worklog.sh com o config temporário (via cópia que usa o CFG do tmp)
run() { ( cd "$SCRIPT_DIR" && CONFIG_OVERRIDE="$CFG" bash -c '
    SCRIPT_DIR="'"$SCRIPT_DIR"'"
    # injeta o config temporário sobrescrevendo a var CONFIG do script
    sed "s#CONFIG=\"\$SCRIPT_DIR/config.json\"#CONFIG=\"$CONFIG_OVERRIDE\"#" "$SCRIPT_DIR/worklog.sh" > "'"$TMP"'/wl.sh"
    bash "'"$TMP"'/wl.sh" "$@"
  ' _ "$@" ); }

fail() { echo "FALHOU: $1" >&2; exit 1; }

# 1) ensure-daily cria o arquivo com as 5 seções (layout minimal elegante)
run ensure-daily 2026-06-09 >/dev/null
F="$VAULT/daily/2026-06-09.md"
[ -f "$F" ] || fail "daily não foi criada"
for sec in "## 📋 Plano" "## ✅ Feito" "## 🚧 Impedimentos" "## 💡 Decisões / Aprendizados" "### 🗣️ Para a daily de amanhã"; do
  grep -qF "$sec" "$F" || fail "seção ausente: $sec"
done
grep -qF "# 📅 09 jun · terça" "$F" || fail "cabeçalho/data legível errado"
grep -qF "tags: [daily]" "$F" || fail "frontmatter sem tags"
grep -qF "> [!abstract] Resumo do dia" "$F" || fail "callout de resumo ausente"

# 2) idempotência: rodar de novo não duplica nem apaga
before="$(md5sum "$F" | cut -d' ' -f1)"
out="$(run ensure-daily 2026-06-09)"
after="$(md5sum "$F" | cut -d' ' -f1)"
[ "$before" = "$after" ] || fail "ensure-daily não é idempotente"
echo "$out" | grep -q "já existe" || fail "não sinalizou 'já existe'"

# 3) paths resolve a vault
paths_out="$(run paths)"
echo "$paths_out" | grep -q '^vault:' || fail "paths não imprimiu linha 'vault:'"
echo "$paths_out" | grep -qF "$VAULT" || fail "paths não resolveu a vault ($VAULT)"

echo "OK — todos os testes passaram"
