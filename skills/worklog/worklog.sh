#!/usr/bin/env bash
# worklog.sh — IO mecânica da vault WorkLog (diário de trabalho dirigido por IA).
#
# Faz só o trabalho braçal e determinístico: chamar o overview-do-dia (read-only no
# Monday), coletar os commits do dia nas worktrees, e garantir o esqueleto da daily.
# A PROSA (síntese da daily/frentes/impedimentos/retro) é escrita pela IA seguindo o
# AGENTS.md da vault — NÃO por este script.
#
# Uso:
#   ./worklog.sh paths                 # mostra caminhos resolvidos + data de hoje
#   ./worklog.sh ensure-daily [DATA]   # cria daily/<DATA>.md (esqueleto) se faltar
#   ./worklog.sh abrir [MODO] [DATA]   # overview -> raw/<DATA>/monday.json + daily
#   ./worklog.sh git-dia [DATA]        # commits do autor no dia -> raw/<DATA>/git.md
#   ./worklog.sh fechar [MODO] [DATA]  # abrir(MODO|fim) + git-dia juntos
#
# MODO: inicio | meio | fim   (default: deixa o overview inferir pela hora)
# DATA: AAAA-MM-DD            (default: hoje)
#
# Requer: jq, git, e (para abrir/fechar) MONDAY_API_TOKEN exportado.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"
[ -f "$CONFIG" ] || { echo "worklog.sh: config.json não encontrado em $SCRIPT_DIR" >&2; exit 1; }
command -v jq >/dev/null || { echo "worklog.sh: jq é obrigatório no PATH" >&2; exit 1; }

cfg() { jq -r "$1" "$CONFIG"; }
expand_tilde() { case "$1" in "~"|"~/"*) printf '%s\n' "${HOME}${1#\~}";; *) printf '%s\n' "$1";; esac; }

VAULT="$(expand_tilde "$(cfg '.vault_path')")"
GIT_AUTHOR="$(cfg '.git_author')"
OVERVIEW="$SCRIPT_DIR/$(cfg '.overview_script')"

today() { date +%Y-%m-%d; }

weekday_pt() {
  case "$(date -d "$1" +%u 2>/dev/null || date +%u)" in
    1) echo "segunda";; 2) echo "terça";; 3) echo "quarta";; 4) echo "quinta";;
    5) echo "sexta";; 6) echo "sábado";; 7) echo "domingo";; *) echo "";;
  esac
}

# Data legível pt-BR para o título: "DD mmm · dia-da-semana" (ex.: "09 jun · terça").
daylabel_pt() {
  local d="$1" dd mm
  dd="$(date -d "$d" +%d 2>/dev/null || echo "$d")"
  case "$(date -d "$d" +%m 2>/dev/null)" in
    01) mm="jan";; 02) mm="fev";; 03) mm="mar";; 04) mm="abr";;
    05) mm="mai";; 06) mm="jun";; 07) mm="jul";; 08) mm="ago";;
    09) mm="set";; 10) mm="out";; 11) mm="nov";; 12) mm="dez";; *) mm="";;
  esac
  printf '%s %s · %s' "$dd" "$mm" "$(weekday_pt "$d")"
}

ensure_vault() {
  [ -d "$VAULT" ] || { echo "worklog.sh: vault não encontrada em $VAULT (veja config.json)" >&2; exit 1; }
  mkdir -p "$VAULT/raw" "$VAULT/daily" "$VAULT/frentes" "$VAULT/impedimentos" "$VAULT/retro"
}

ensure_daily() {
  local d="${1:-$(today)}"
  ensure_vault
  local f="$VAULT/daily/$d.md"
  if [ -f "$f" ]; then echo "$f (já existe)"; return 0; fi
  local label; label="$(daylabel_pt "$d")"
  cat > "$f" <<EOF
---
type: daily
data: $d
tags: [daily]
---

# 📅 $label

> [!abstract] Resumo do dia
> _(N itens · N atrasados · foco em …)_

## 📋 Plano

## ✅ Feito

## 🚧 Impedimentos

## 💡 Decisões / Aprendizados

---

### 🗣️ Para a daily de amanhã
EOF
  echo "$f (criado)"
}

abrir() {
  local modo="${1:-}" d="${2:-$(today)}"
  ensure_vault
  [ -x "$OVERVIEW" ] || { echo "worklog.sh: overview.sh não encontrado/executável: $OVERVIEW" >&2; exit 1; }
  mkdir -p "$VAULT/raw/$d"
  local out="$VAULT/raw/$d/monday.json"
  echo "→ rodando overview-do-dia ${modo:-(modo automático)}..." >&2
  if [ -n "$modo" ]; then "$OVERVIEW" "$modo" > "$out"; else "$OVERVIEW" > "$out"; fi
  echo "snapshot salvo: $out" >&2
  ensure_daily "$d" >&2
  cat "$out"
}

git_dia() {
  local d="${1:-$(today)}"
  ensure_vault
  mkdir -p "$VAULT/raw/$d"
  local out="$VAULT/raw/$d/git.md"
  local since="$d 00:00:00" until="$d 23:59:59"
  {
    echo "# Commits de $d — autor: $GIT_AUTHOR"
    echo
    local repos; repos="$(cfg '.repos[]')"
    while IFS= read -r repo; do
      [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || { continue; }
      # cada worktree do repo
      local wt branch
      while IFS= read -r line; do
        case "$line" in
          worktree\ *) wt="${line#worktree }";;
          branch\ *) branch="${line#branch refs/heads/}";;
          "")
            if [ -n "${wt:-}" ] && [ -d "$wt" ]; then
              local log
              log="$(git -C "$wt" log --no-merges --since="$since" --until="$until" \
                     --author="$GIT_AUTHOR" --pretty='- %h %s' 2>/dev/null || true)"
              if [ -n "$log" ]; then
                echo "## $(basename "$wt") [${branch:-?}]"
                echo "$log"
                echo
              fi
            fi
            wt=""; branch=""
            ;;
        esac
      done < <(git -C "$repo" worktree list --porcelain 2>/dev/null; echo)
    done <<< "$repos"
  } > "$out"
  echo "git do dia salvo: $out" >&2
  cat "$out"
}

fechar() {
  local modo="${1:-fim}" d="${2:-$(today)}"
  abrir "$modo" "$d" >/dev/null
  echo "---" >&2
  git_dia "$d"
}

cmd="${1:-paths}"; shift || true
case "$cmd" in
  paths)
    echo "vault:    $VAULT"
    echo "overview: $OVERVIEW"
    echo "autor:    $GIT_AUTHOR"
    echo "hoje:     $(today) ($(weekday_pt "$(today)"))"
    ;;
  ensure-daily) ensure_daily "${1:-}";;
  abrir)        abrir "${1:-}" "${2:-}";;
  git-dia)      git_dia "${1:-}";;
  fechar)       fechar "${1:-}" "${2:-}";;
  *) echo "worklog.sh: subcomando desconhecido '$cmd' (use: paths|ensure-daily|abrir|git-dia|fechar)" >&2; exit 1;;
esac
