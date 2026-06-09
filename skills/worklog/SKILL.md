---
name: worklog
description: Use quando o usuário quiser registrar/organizar o trabalho do dia na vault WorkLog (diário dirigido por IA) para alimentar daily e retro — "abre o dia", "registra isso", "anota que travei em X", "fecha o dia", "faz a retro", "o que falo na daily". Opera a vault ~/Documents/WorkLog (padrão Karpathy adaptado): captura bruta de Monday+git em raw/ e a IA sintetiza daily/, frentes/, impedimentos/ e retro/.
---

# worklog

## Overview

Mantém a vault **WorkLog** (`~/Documents/WorkLog`), um **diário de trabalho temporal**
escrito majoritariamente pela IA, para o usuário ter material pronto pra **daily** e
**retro**. Segue o padrão **LLM Wiki do Karpathy**: `raw/` é a camada bruta imutável
(snapshots de Monday + commits do dia + notas), e `daily/`, `frentes/`,
`impedimentos/`, `retro/` são sintetizados e interligados pela IA.

- **Fontes:** Monday (via `overview-do-dia`/`monday-api`, **read-only**), git/código
  (commits do dia nas worktrees), conversas com a IA, notas manuais.
- **Divisão de trabalho:** `worklog.sh` faz só a IO mecânica (chamar o overview,
  coletar git, garantir o esqueleto da daily). **A prosa é VOCÊ (a IA) que escreve**,
  lendo o `raw/` e seguindo o `AGENTS.md` da vault.
- **Idioma:** tudo em português (regra da base).

## Regra de ouro

- **Nunca** chame a API do Monday direto. Leitura do Monday só via `overview-do-dia`
  (que por baixo usa o gateway `monday.sh` da skill `monday-api`).
- **`raw/` é imutável** — só anexe capturas, nunca reescreva.
- **Anti-alucinação:** "Feito" só entra se vier de `raw/` (Monday/git) ou for
  confirmado pelo usuário. Não invente entregas; cite a fonte de cada fato.
- Esta skill **não** escreve no Monday. Se o usuário pedir uma ação no Monday, isso é
  a skill `monday-api`, com confirmação.

## Pré-requisitos

- `MONDAY_API_TOKEN` exportado (para `abrir`/`fechar`):
  `export MONDAY_API_TOKEN="$(cat ~/.config/monday/token)"`.
- `jq`, `git`. Vault em `~/Documents/WorkLog` (caminho em `config.json`).

## Procedimento (os 4 verbos)

Rode os comandos a partir da pasta da skill. Sempre **leia o `AGENTS.md` da vault**
antes de escrever prosa.

### 1. abrir o dia (manhã / "abre o dia", "o que tenho pra hoje")
```bash
export MONDAY_API_TOKEN="$(cat ~/.config/monday/token)"
./worklog.sh abrir inicio
```
Isso salva `raw/<hoje>/monday.json` e garante `daily/<hoje>.md`. **Você então:**
- Preenche a seção **Plano** da daily, priorizado (atrasados → reprovados/reviews →
  em andamento → a fazer), lendo o JSON impresso.
- Traz **impedimentos abertos** relevantes de `impedimentos/` pro topo.
- Anexa entrada `abrir-dia` no `log.md` e atualiza "Últimas dailies" no `index.md`.

### 2. registrar (durante / "registra isso", "anota que…")
- O usuário relata um avanço/decisão/impedimento (ou você capta da própria sessão).
- Garanta a daily: `./worklog.sh ensure-daily`.
- **Você escreve:** anexa na daily de hoje (Feito / Impedimentos / Decisões) **e**
  atualiza a `frentes/<slug>.md` correspondente e/ou abre/atualiza
  `impedimentos/<slug>.md` (frontmatter `status`, `aberto_em`).
- Para notas cruas longas do usuário, salve também em `raw/<hoje>/notas.md`.

### 3. fechar o dia (fim / "fecha o dia", "encerrar")
```bash
export MONDAY_API_TOKEN="$(cat ~/.config/monday/token)"
./worklog.sh fechar fim
```
Salva `raw/<hoje>/monday.json` (modo fim) e `raw/<hoje>/git.md`. **Você então:**
- Completa **Feito** (correlacionando os commits do `git.md` às frentes — use o mapa
  `frentes` do `config.json` como dica, mas confie no que o git reportou) e
  **Impedimentos**; marca impedimentos resolvidos com data.
- Escreve o bloco **"Para a daily de amanhã"** (fiz / farei / travado em).
- Atualiza `frentes/`, `index.md`; anexa `fechar-dia` no `log.md`.

### 4. fazer a retro (fim de sprint/semana / "faz a retro")
- Leia as `daily/AAAA-MM-DD.md` do período (ex.: a semana ISO).
- Gere `retro/AAAA-Www.md`: entregas, impedimentos **recorrentes**, decisões, ações
  de melhoria. Interligue com `[[frentes/...]]` e `[[impedimentos/...]]`.
- Anexe `retro` no `log.md`.

## Tratamento de erros

- Token ausente → peça `export MONDAY_API_TOKEN=...` (não contorne).
- `git.md` vazio → dia sem commits do autor; registre só o que veio do Monday/relato.
- Worktree/branch divergente do `CLAUDE.md` → normal (branches mudam); use o que o
  `git-dia` reportou e ajuste o mapa de `frentes` no `config.json` se quiser.

## Configuração (`config.json`)

- `vault_path`: caminho da vault (suporta `~`).
- `git_author`: autor usado no `git log` (default do projeto: `cako`).
- `repos`: raízes de repo varridas pelo `git-dia` (cada uma cobre suas worktrees).
- `overview_script`: caminho relativo pro `overview.sh`.
- `frentes`: mapa frente→branches, só dica pra você correlacionar commits.

## Teste (sem rede)

```bash
./test-worklog.sh
```
Cria uma vault temporária e valida o `ensure-daily` (seções + idempotência), sem
tocar no Monday.
