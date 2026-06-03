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

5. **Testes unitários passam** (obrigatório)

   Rode a bateria de testes unitários do repo desta worktree. O comando vem do
   `CLAUDE.md` da worktree (campo "Testes unitários"); se não declarado, descubra pelo
   `package.json`/configuração do projeto (ex.: `pnpm vitest:unit`, `npm test`).
   Se **falhar** → **BLOQUEIA**: conserte (use `superpowers:systematic-debugging`)
   antes de commitar. Não commite com unit test vermelho.

   Antes de afirmar que passou, aplique `superpowers:verification-before-completion`:
   evidência (saída real do teste) antes de qualquer afirmação de sucesso.

## Se tudo passar

Reporte e prossiga:

> ✅ commit liberado — frente `<type>-<slug>`, repo `<repo>`, branch `<type>/<slug>`,
> unit tests verdes.

Mensagem de commit: **em pt-br**, **conventional commits**, **subject-only** (sem
parágrafo de corpo) e com o footer de co-autoria do projeto. Ex.:

```
feat: adiciona compartilhamento de contatos no atendimento

Co-Authored-By: <conforme padrão do projeto>
```

## Se falhar

Explique **qual** checagem falhou e a correção sugerida (ex.: "você está em
`develop`; troque para a branch da frente `feat/atendimentos-grupos` antes de
commitar" ou "você está no repo raiz `web-pharmachatbot`; vá para a worktree em
`worktrees/<frente>/web-pharmachatbot`"). **Não commite.**
