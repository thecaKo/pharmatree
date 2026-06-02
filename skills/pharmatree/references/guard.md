# Procedimento: guard (checklist de pré-commit)

**Rode SEMPRE antes de `git commit`** dentro desta base. Regra: *pasta == branch +
branches protegidas bloqueadas*. Se qualquer checagem falhar → **recuse o commit e
reporte**; não commite.

## Checklist

1. **Confinamento — não é repo raiz**

   ```bash
   git rev-parse --show-toplevel
   ```
   O caminho DEVE estar dentro de `worktrees/<frente>/<repo>`. Se for um repo raiz
   (origem) → **BLOQUEIA**: repos raiz nunca recebem commit.

2. **Confinamento — mudanças não vazam**

   ```bash
   git status --porcelain
   ```
   Todos os arquivos staged/modificados devem pertencer a esta worktree. Nada de
   paths apontando para fora dela.

3. **Branch protegida**

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   Se a branch for `main`, `master` ou `develop` → **BLOQUEIA**. Frente trabalha em
   branch própria `<type>/<slug>`.

4. **Pasta == branch**

   - Frente = penúltima pasta do caminho: `worktrees/<frente>/<repo>` → `<frente>`.
   - Branch esperada = `<frente>` com o **primeiro** `-` trocado por `/`.
   - A branch atual DEVE ser igual à esperada. Divergência silenciosa → **BLOQUEIA**.

## Se tudo passar

Reporte e prossiga:

> ✅ commit liberado — frente `<type>-<slug>`, repo `<repo>`, branch `<type>/<slug>`.

Mensagem de commit: **conventional + subject-only** (sem parágrafo de corpo) e com o
footer de co-autoria do projeto. Ex.:

```
feat: adiciona compartilhamento de contatos no atendimento

Co-Authored-By: <conforme padrão do projeto>
```

## Se falhar

Explique **qual** checagem falhou e a correção sugerida (ex.: "você está em
`develop`; troque para a branch da frente `feat/atendimentos-grupos` antes de
commitar" ou "você está no repo raiz `web-pharmachatbot`; vá para a worktree em
`worktrees/<frente>/web-pharmachatbot`"). **Não commite.**
