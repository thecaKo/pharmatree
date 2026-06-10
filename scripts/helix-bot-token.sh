#!/usr/bin/env bash
#
# helix-bot-token.sh — gera um installation token (válido ~1h) de um GitHub App
# para o `gh` comentar nas PRs como `<app>[bot]` em vez da conta do usuário.
#
# Uso (faz `eval`/`source` pra exportar GH_TOKEN no shell atual):
#
#   eval "$(scripts/helix-bot-token.sh)"
#   gh pr comment ...   # agora comenta como o bot
#
# Config — defina via env OU num arquivo de config fora do versionamento.
# Procura, nesta ordem:
#   1. variáveis de ambiente HELIX_BOT_APP_ID / HELIX_BOT_KEY_PATH / HELIX_BOT_INSTALL_ID
#   2. arquivo ~/.helix/bot.env (mesmas variáveis, formato KEY=VALUE)
#
# Requisitos: gh CLI autenticado (qualquer conta) + extensão actions/gh-token:
#   gh extension install actions/gh-token

set -euo pipefail

CONFIG_FILE="${HELIX_BOT_CONFIG:-$HOME/.helix/bot.env}"

# Carrega config do arquivo se as envs não estiverem setadas.
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$CONFIG_FILE"; set +a
fi

err() { echo "helix-bot-token: $*" >&2; }

missing=0
for var in HELIX_BOT_APP_ID HELIX_BOT_KEY_PATH HELIX_BOT_INSTALL_ID; do
  if [[ -z "${!var:-}" ]]; then
    err "faltando $var (defina via env ou em $CONFIG_FILE)"
    missing=1
  fi
done
[[ "$missing" -eq 0 ]] || { err "config incompleta — abortando"; exit 1; }

if [[ ! -f "$HELIX_BOT_KEY_PATH" ]]; then
  err "private key não encontrada em: $HELIX_BOT_KEY_PATH"
  exit 1
fi

if ! gh token generate --help >/dev/null 2>&1; then
  err "extensão 'actions/gh-token' não instalada. Rode: gh extension install actions/gh-token"
  exit 1
fi

token="$(gh token generate \
  --app-id "$HELIX_BOT_APP_ID" \
  --key "$HELIX_BOT_KEY_PATH" \
  --installation-id "$HELIX_BOT_INSTALL_ID" \
  --token-only)"

if [[ -z "$token" ]]; then
  err "falha ao gerar o token (gh token generate retornou vazio)"
  exit 1
fi

# Saída pra ser consumida com eval "$(...)".
echo "export GH_TOKEN=$token"
