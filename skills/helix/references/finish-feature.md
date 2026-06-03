# Procedimento: finish-feature (fechar feature + testes de integração)

Use ao concluir uma feature/frente, antes de abrir PR ou integrar. Roda os **testes
de integração** — mas **somente se o ambiente de teste já estiver pronto**. O agente
**nunca sobe infra por conta própria** (docker, migrations, seeds): se faltar algo,
ele apenas reporta e para.

## Passos

1. **Confirme o contexto** com `where-am-i` (frente, repos, branch). Garanta que toda
   a feature já foi commitada via `guard` (unit tests verdes em cada repo).

2. **Verifique se o ambiente de testes está pronto** (somente checagens *read-only*):
   - containers de teste no ar? `docker ps` mostra os serviços esperados
     (ex.: MySQL/Redis de teste)?
   - banco acessível e **migrations** aplicadas? (ping/health-check do projeto)
   - **seeds** carregadas, se a suíte exigir?

   O comando/health-check exato vem do `CLAUDE.md` da worktree (campo "Ambiente de
   integração"). Não recrie nem suba nada — apenas observe.

3. **Decisão:**
   - **Ambiente pronto** → rode a bateria de **testes de integração** do repo
     (campo "Testes de integração" do `CLAUDE.md` da worktree; ex.:
     `pnpm vitest:integration`). Use `superpowers:verification-before-completion`:
     reporte a saída real. Se falhar → `superpowers:systematic-debugging`.
   - **Ambiente NÃO pronto** → **não execute** os testes. Reporte exatamente o que
     falta e **liste os comandos** para o usuário preparar o ambiente (ex.:
     `docker compose up -d`, `pnpm test:db:init`, seeds). Marque a feature como
     "integração pendente — aguardando ambiente/execução manual".

4. **Repita** o passo 3 para cada repo envolvido na frente que tenha suíte de
   integração.

5. **Fechar a branch:** quando os testes (que puderam rodar) estiverem verdes, use
   `superpowers:finishing-a-development-branch` para decidir merge / PR / cleanup da
   frente. Atualize o status no **Mapa de frentes ativas** do `CLAUDE.md` raiz.

## Regra de ouro

O agente **observa** o ambiente, não o **provisiona**. Suítes Mongo in-memory
(MongoMemoryServer) não dependem de infra externa e podem rodar normalmente; suítes
que exigem MySQL/Redis/Docker só rodam se o usuário já tiver subido o ambiente.
