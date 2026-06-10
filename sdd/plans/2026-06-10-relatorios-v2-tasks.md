# Plano — Relatórios v2 (frente feat-relatorios-v2)

**Goal:** Tela de Relatórios v2 (catálogo de 12 cards + drawer) atrás de feature flag, com 8 relatórios servidos pela neo-api com dados reais do MySQL transacional via queries agregadas performáticas.

**Arquitetura:** Novo módulo `reports` na neo-api (NestJS + Drizzle) com 1 endpoint de envelope único (`GET /reports/:reportId?period=`) e um service por relatório (queries agregadas, sem N+1, multi-tenant por `companyId`, janelas atual+anterior para `trendPct`). No web, nova página `ReportsV2` (React + styled-components + recharts) seguindo o design handoff adaptado aos tokens do `design.md`; rota `/reports` alterna entre tela legada e v2 via feature flag por empresa. Flag criada por migration idempotente nos dois repos que compartilham o banco (api legada Sequelize + neo Drizzle).

**Stack:** neo: NestJS + Drizzle ORM (MySQL) + Vitest + Biome (pnpm) · web: React 18 + Vite + styled-components + MUI v5 + recharts + TanStack Query + Vitest (npm) · api legada: Express + Sequelize (npm).

**Spec:** `~/Documents/projetos/pharmachatbot/docs/Reports/PRD-reconstrucao-relatorios.md` + handoff `~/Documents/projetos/pharmachatbot/docs/Reports/design_handoff_relatorios/` (README.md = fonte da UI).

**Decisões de escopo (confirmadas com o usuário em 2026-06-10):**
- 8 relatórios com dados reais: `tickets`, `status`, `users`, `client`, `contacts`, `occurrence`, `crm`, `pix`. Os 4 restantes (`avgtime`, `research`, `agendamento`, `gagenda`) aparecem no catálogo como "em breve" (card desabilitado).
- Dados reais via queries diretas no MySQL transacional (snapshots do dashboard-v2 NÃO estão merjados — não usar).
- Export PDF/Excel FORA desta entrega: botões visíveis porém desabilitados com tooltip "Em breve".
- Migration da flag nos dois repos (api legada + neo), idempotente (mesmo banco físico).

---

## Context Pack

> Injetar verbatim em cada subagente.

### Worktrees (NUNCA tocar nos repos raiz)
- web: `/home/cako/Documents/projetos/pharmatree/worktrees/feat-relatorios-v2/web-pharmachatbot` (branch `feat/relatorios-v2`)
- neo: `/home/cako/Documents/projetos/pharmatree/worktrees/feat-relatorios-v2/neo-api-pharmachatbot` (branch `feat/relatorios-v2`)
- api legada: `/home/cako/Documents/projetos/pharmatree/worktrees/feat-relatorios-v2/api-pharmachatbot` (branch `feat/relatorios-v2`)

### Comandos (rodar na worktree do repo correspondente)
| Repo | Unit tests | Lint | Build |
|---|---|---|---|
| neo | `pnpm vitest:unit` | `pnpm lint` (Biome) | `pnpm build` |
| web | `npm run test` (Vitest) | `npm run lint` (Biome) | `npm run build` |
| api legada | `npm run test` (Vitest) | `npm run lint` | — |

Migrations: neo = Drizzle Kit (`pnpm db:generate`, SQL versionado em `src/drizzle/migrations/*.sql`); api legada = sequelize-cli (`src/database/migrations/`, padrão timestamp-nome.js).

### Convenções obrigatórias
- **Idioma:** comunicação e strings de UI em pt-BR (strings hard-coded no componente, SEM i18n). Commits pt-BR, conventional, subject-only + footer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- **neo — módulo padrão** (`src/modules/<mod>/`): `controllers/`, `services/`, `repositories/` (queries Drizzle), `dtos/` (class-validator), `interfaces/`, `<mod>.module.ts`, `README.md`. Envelope global `{ success, message, data, error }` via `@ApiEnvelopeResponse(DTO)` (`src/common/swagger/envelope.dto.ts`). Erros via subclasses de `AppException`. Schema Drizzle único: `src/drizzle/schema.ts`.
- **neo — auth/multi-tenant:** `JwtAuthGuard` global; `@CurrentUser()` dá `user` com `company_id` e `profile.tag` (`admin` | `user` | `superAdmin`). TODA query filtra `companyId` (e `deletedAt IS NULL`).
- **neo — feature flags:** módulo `src/modules/feature-flags/`; tabelas `feature_flags` (id UUID, name UNIQUE, is_active, description) e `company_feature_flags` (company_id, feature_flag_id, is_enabled). Util `HasFeatureFlag` em `src/common/utils/has-feature-flag`.
- **neo — timezone:** dayjs + plugin timezone, constante `'America/Sao_Paulo'` (padrão do repo; não existe TZ por empresa).
- **web — padrão de tela v2** (espelhar `src/pages/AtendimentosV2/` e `src/pages/Dashboard/`): `index.tsx` + `components/` + `hooks/` + `services/` + `queries/` + `dtos/` + `styles.ts` (styled-components).
- **web — client neo:** `src/services/neoApi.tsx` (axios, baseURL `VITE_REACT_APP_NEO_BACKEND_URL`, Bearer do localStorage `@Greenchat:token`).
- **web — feature flag por empresa:** hook `useFeatureFlag(nomeDaFlag)` em `src/hooks/useFeatureFlag.ts` → `{ hasAccess, isLoading }`; superAdmin sempre tem acesso. Auth: `useAuth()` de `src/hooks/Auth/index.tsx`.
- **web — rota atual:** `/reports` registrada em `src/routes/list.routes.tsx` (importa `src/pages/Reports/index.tsx`); menu em `src/layout/utils/modules.ts` (perfil `admin`). A v2 NÃO cria rota nova: alterna o elemento da rota `/reports` pela flag.
- **Design:** seguir `design.md` da raiz do hub (`/home/cako/Documents/projetos/pharmatree/design.md`). Tokens: `primary-base #e6284a` (hover `primary-dark #cc2443`), cards `radius 18px` + `SHADOW_MD`, inputs/botões `radius 0.75rem`, borda `rgba(0,0,0,0.06)`, texto `#605E70`/`#737185`, badges `radius full` + overline. Paleta categórica de gráficos SÓ em gráficos. TODA animação dentro de `@media (prefers-reduced-motion: no-preference)`. O handoff usa hex próprios (`#e8395a` etc.) — **substituir pelos tokens do design.md**; gradientes de categoria são os tokens novos `report-cat-*` (adicionados ao design.md pela T1).
- **Nome da feature flag (string literal única):** `relatorios-v2`.

### Regras de negócio (PRD)
- Status de ticket: `1/9 → pendente`, `2 → aberto`, `3 → fechado`, `7 → pesquisa` (fechado p/ fins de "resolvido": 3 e 7).
- Venda: `is_sale = true` AND `status_id IN (3,7)` AND `service_not_made = false` (em `group_tickets` não há `service_not_made` — omitir essa condição lá). Relatório `crm` agrega `tickets` UNION ALL `group_tickets`.
- `trendPct`: variação % vs. janela anterior contígua de mesmo tamanho; `null` (não `NaN`/`Infinity`) se a janela anterior não tem dados.
- Períodos: `today | 7d | 30d | quarter` (default 30d), no TZ `America/Sao_Paulo`.
- Período vazio → envelope válido com zeros (nunca 500).
- KPIs com valor numérico cru + `unit` (`count` | `pct` | `brl` | `seconds`); formatação pt-BR no front.
- Badge de tabela calculada no backend: `{ tag: 'green'|'amber'|'red'|'blue', text }`.
- Acesso: tela é admin-only (paridade com o legado) → endpoint exige `profile.tag` ∈ {admin, superAdmin}; senão 403.

### Schema MySQL (colunas-chave; snake_case no banco, camelCase no Drizzle)
- `tickets`: id, company_id, status_id, contact_id, attendant_user_id, is_sale, sale_price (STRING), service_not_made, ocurrence (STRING), origin, connection_id, created_at, updated_at, deleted_at. Índices: `idx_tickets_company_updated`, `idx_tickets_company_updated_status`, `idx_tickets_company_updated_conn_status`.
- `group_tickets`: id, company_id, group_id, status_id, contact_id, attendant_id, is_sale, sale_price, reasons_id, created_at, updated_at, deleted_at. Índice: `idx_gt_company_updated_status_group`.
- `contacts`: id, company_id, name, number, email, origin, created_at, deleted_at. Índice: `idx_contacts_number_company_id`.
- `users`: id, company_id, profile_id, name, email.
- `crm_sales_reasons`: id, reason, color, company_id.
- `pix_payment`: id, ticket_id (FK→tickets), amount DECIMAL(15,2), tax, pix_code, transaction_id, status ENUM(pending|accepted|rejected|expired), created_user_by_id, created_at. **Sem company_id próprio** → filtrar por JOIN em tickets.company_id.
- Drizzle: tudo em `src/drizzle/schema.ts` (tickets :4517, groupTickets :2146, contacts :1711, users :4826, pixPayment :2998, historicTickets :2325).

### Performance (inviolável)
- Cada relatório responde com **número FIXO de queries** (tipicamente 2–4: janela atual, janela anterior, série do gráfico, tabela Top-N). **PROIBIDO** query dentro de laço (N+1). Top-N com JOIN (ex.: nome do atendente via JOIN users), nunca busca por linha.
- Agregação no SQL (`COUNT/SUM/GROUP BY`), nunca em JS sobre row-level.
- Ranges de data sempre **sargáveis**: `created_at >= :from AND created_at < :to` (nunca `DATE(created_at) = ...`), para usar os índices `idx_*_company_updated`.
- `sale_price` é STRING → `CAST(... AS DECIMAL(15,2))` no SQL.
- **Política de review N+1 (exigência do usuário):** ao fim de CADA task de L2/L3 que cria query, a fast-exec dispara um agente revisor com o prompt: "Audite os arquivos <repository/service da task> contra N+1 (query em laço, await em map/for, falta de JOIN), ranges não-sargáveis e agregação em JS; confira que os filtros usam companyId + created_at compatíveis com os índices listados no Context Pack. Vereditos: aprovado | reprovado com lista de correções." Reprovado → corrigir antes do commit da task.

### Envelope do endpoint (contrato; tipos definidos na T2/T6)
`GET /reports/:reportId?period=today|7d|30d|quarter` → `data`:
```ts
{
  reportId: string,
  period: { key: string, from: string, to: string },        // ISO no TZ SP
  kpis: Array<{ key: string, label: string, value: number, unit: 'count'|'pct'|'brl'|'seconds', trendPct: number|null }>, // sempre 3
  chart: { type: 'bars', series: Array<{ label: string, a: number, b?: number }>, legend: Array<{ color: string, label: string }> }
       | { type: 'donut', slices: Array<{ label: string, value: number, color: string }> },
  table: { cols: string[], rows: Array<{ id: number|string, cells: Array<string|number>, badge?: { tag: 'green'|'amber'|'red'|'blue', text: string } }>, total: number,
           pagination?: { page: number, pageSize: number } }   // só pix
}
```
Cores em `chart` = paleta categórica do design.md (gráficos somente).

### Catálogo (front, estático — RF02)
12 relatórios, 4 categorias (handoff `app/data.jsx`): atendimento (tickets, status, occurrence, avgtime), clientes (users, client, contacts), engajamento (research, agendamento, gagenda), financeiro (crm, pix). `avgtime`, `research`, `agendamento`, `gagenda` → `comingSoon: true`.

---

## Tasks

### Camada L1 — Fundações (todas [P], arquivos disjuntos)

#### T1 [P] [fast] — Tokens de categoria no design.md (L1)
**Arquivos:** Edit: `/home/cako/Documents/projetos/pharmatree/design.md`
**Aceitação:** seção/tokens novos `report-cat-atendimento|clientes|engajamento|financeiro` com par accent/accent2 derivado da marca (atendimento usa `primary-base #e6284a`/`primary-light #f15976`; demais reaproveitam a família primary + tons já documentados ou registram os do handoff `#f0508a/#ff7eb0`, `#f06a45/#ff9166`, `#c4407e/#e668a8` como tokens de **ícone de categoria de relatório**, com nota "uso exclusivo nos ícones/gradientes do catálogo de relatórios — nunca em botões/texto"). Documento permanece consistente (frontmatter YAML válido).
**Testes:** n/a (doc) — verificação: YAML do frontmatter parseia (`python3 -c "import yaml,sys; yaml.safe_load(open('design.md').read().split('---')[1])"`).

#### T2 [P] [opus] — Scaffolding do módulo reports na neo (L1)
**Arquivos:** Create: `src/modules/reports/reports.module.ts`, `src/modules/reports/controllers/reports.controller.ts`, `src/modules/reports/dtos/get-report.dto.ts`, `src/modules/reports/interfaces/report-envelope.interface.ts`, `src/modules/reports/README.md` · Edit: `src/app.module.ts` (registrar módulo) · Test: `src/modules/reports/controllers/reports.controller.spec.ts`
**Aceitação:** `GET /reports/:reportId?period=` existe com validação do DTO (`period` ∈ today|7d|30d|quarter, default 30d; `page`/`pageSize` opcionais para pix); guard de perfil: `profile.tag` user → 403 (`AppException`); `reportId` desconhecido → 404; controller delega a um `ReportsService.resolve(reportId, ...)` ainda com mapa vazio (todo id conhecido lança 501 "não implementado" temporário). Interface `ReportEnvelope` = contrato do Context Pack. Swagger com `@ApiEnvelopeResponse`.
**Testes:** controller.spec: 403 para perfil user; 404 para id desconhecido; period inválido → 400; period default = 30d.

#### T3 [P] [fast] — Util de janelas de período (neo) (L1)
**Arquivos:** Create: `src/modules/reports/utils/period.util.ts` · Test: `src/modules/reports/utils/period.util.spec.ts`
**Aceitação:** `resolvePeriod(key, now?)` → `{ from, to, prevFrom, prevTo, key }` em TZ `America/Sao_Paulo`: `today` = início do dia local→agora (prev = ontem mesmo horário); `7d`/`30d` = N dias até agora (prev = N dias contíguos anteriores); `quarter` = 90 dias. Datas retornadas como `Date` UTC corretos.
**Testes:** cada key com `now` fixo (incluindo virada de dia em UTC≠SP); janelas prev contíguas e de mesmo tamanho; quarter = 90 dias.

#### T4 [P] [fast] — Migration da flag na api legada (L1)
**Arquivos:** Create: `src/database/migrations/<timestamp>-seed-feature-flag-relatorios-v2.js`
**Aceitação:** migration Sequelize insere em `feature_flags` a flag `name='relatorios-v2'`, `is_active=true`, `description='Tela de Relatórios v2 servida pela neo-api'` **somente se não existir** (idempotente — `INSERT ... SELECT ... WHERE NOT EXISTS` ou check prévio); `down` remove apenas se foi criada por ela (delete por name). UUID gerado na migration. Segue o padrão das migrations `20260204120000-create-table-feature-flags.js`.
**Testes:** `npx sequelize-cli db:migrate` numa base de teste aplica sem erro 2× (a 2ª por reversão+reaplicação) — na prática: revisar idempotência por inspeção + unit não se aplica; aceitação verificada por dry-run de SQL no review.

#### T5 [P] [fast] — Migration da flag na neo (L1)
**Arquivos:** Create: `src/drizzle/migrations/<próximo-número>_seed-feature-flag-relatorios-v2.sql` (+ entrada no journal de migrations do Drizzle, se o repo versiona `meta/_journal.json`)
**Aceitação:** SQL `INSERT INTO feature_flags (...) SELECT ... WHERE NOT EXISTS (SELECT 1 FROM feature_flags WHERE name='relatorios-v2' AND deleted_at IS NULL)` — idempotente e inofensivo se a migration da T4 já rodou (mesmo banco físico). Segue numeração/formato das migrations existentes.
**Testes:** SQL aplica 2× sem erro nem duplicata (verificável por inspeção/review; sem unit).

#### T6 [P] [fast] — Service + queries do front (web) (L1)
**Arquivos:** Create: `src/pages/ReportsV2/services/getReportService.ts`, `src/pages/ReportsV2/queries/useReportQuery.ts`, `src/pages/ReportsV2/dtos/report.dto.ts`
**Aceitação:** `getReportService(reportId, period, page?)` chama `neoApi.get('/reports/'+reportId, { params })` e devolve `data.data` tipado (`ReportEnvelope` espelhando o contrato do Context Pack); `useReportQuery(reportId, period)` usa TanStack Query com key `['reports', reportId, period, page]`, `enabled: !!reportId`, staleTime 60s.
**Testes:** unit do service com axios mockado (params corretos, unwrap do envelope); key da query estável.

#### T7 [P] [fast] — Catálogo estático do front (web) (L1)
**Arquivos:** Create: `src/pages/ReportsV2/catalog.ts`
**Aceitação:** array `REPORTS_CATALOG` com os 12 relatórios (id, categoria, título, descrição pt-BR do handoff `app/data.jsx`, ícone — mapeado para a lib de ícones existente em `src/components/Icons`/MUI mantendo a semântica, `comingSoon` true para avgtime/research/agendamento/gagenda) + `CATEGORIES` com label e par de tokens de cor da T1; labels dos KPIs NÃO ficam aqui (vêm do backend).
**Testes:** unit simples: 12 itens, 4 categorias válidas, exatamente 4 `comingSoon`.

### Camada L2 — Queries por relatório (neo) + componentes (web)

> Cada task neo cria `src/modules/reports/repositories/<id>.repository.ts` + `src/modules/reports/services/<id>-report.service.ts` + spec, SEM tocar em `reports.module.ts`/controller (ligação na T21). Service expõe `build(companyId: number, period: ResolvedPeriod): Promise<ReportEnvelope>`. Specs unitários mockam o repository (não o banco). Todas dependem de T2+T3. **Após cada uma, a fast-exec dispara o agente revisor anti-N+1 (ver Context Pack).**

#### T8 [P] [opus] — Relatório `tickets` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/tickets.repository.ts`, `services/tickets-report.service.ts` · Test: `services/tickets-report.service.spec.ts` (caminhos relativos a `src/modules/reports/`)
**Aceitação:** KPIs: tickets criados no período, resolvidos (status 3/7), taxa de resolução % — cada um com trendPct vs. janela anterior. Chart bars: tickets por dia (label dd/MM, série `a`=criados, `b`=resolvidos), legend com cores da paleta de dados. Tabela Top-10 atendentes (JOIN users; cols Atendente/Tickets/Resolvidos/Taxa; badge: green ≥90%, amber ≥70%, red <70%). Nº fixo de queries ≤4; período vazio → zeros e `trendPct: null`.
**Testes:** taxa calculada certa; trendPct null sem janela anterior; badge nos 3 cortes; repository chamado exatamente N vezes (anti-N+1 no spec).

#### T9 [P] [opus] — Relatório `status` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/status.repository.ts`, `services/status-report.service.ts` · Test: `services/status-report.service.spec.ts`
**Aceitação:** KPIs: abertos (2), pendentes (1/9), fechados (3/7) no período (por created_at), com trendPct. Chart donut: distribuição fechados/abertos/pendentes (cores da paleta de dados). Tabela Top-10 contatos por volume (JOIN contacts; cols Cliente/Abertos/Pendentes/Fechados; badge green se fechados≥80% do total da linha, amber 50–80%, red <50%). Queries fixas ≤3.
**Testes:** mapeamento de status correto (9 conta como pendente, 7 como fechado); donut soma = total; badge nos cortes.

#### T10 [P] [opus] — Relatório `users` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/users.repository.ts`, `services/users-report.service.ts` · Test: `services/users-report.service.spec.ts`
**Aceitação:** KPIs: usuários ativos (atendentes distintos com ticket no período), atendimentos totais, média por usuário (1 casa decimal como number), com trendPct. Chart bars: Top-8 atendentes por atendimentos. Tabela Top-10 usuários (cols Usuário/Atendimentos/Resolvidos/Taxa; badge igual T8). GROUP BY attendant_user_id com JOIN users em UMA query para gráfico+tabela (reuso permitido).
**Testes:** média com divisão por zero → 0; distinct correto; trendPct.

#### T11 [P] [opus] — Relatório `client` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/client.repository.ts`, `services/client-report.service.ts` · Test: `services/client-report.service.spec.ts`
**Aceitação:** KPIs: clientes ativos (contatos distintos com ticket no período), novos no período (contacts.created_at na janela), recorrência % (contatos com ≥2 tickets / ativos), com trendPct. Chart bars: tickets de clientes por semana (ou por dia se period=today/7d). Tabela Top-10 contatos (cols Cliente/Atendimentos/Último contato (dd/MM)/Canal(origin); badge: green ativo ≤2 dias, amber ≤7, red >7 — relativo a `to`). Queries fixas ≤4.
**Testes:** recorrência com 0 ativos → 0 e sem divisão por zero; corte das badges por recência.

#### T12 [P] [opus] — Relatório `contacts` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/contacts.repository.ts`, `services/contacts-report.service.ts` · Test: `services/contacts-report.service.spec.ts`
**Aceitação:** KPIs: novos contatos no período, contatos com ticket (engajados), taxa de engajamento %, com trendPct. Chart donut: novos contatos por canal (`origin`; null → "Outros"). Tabela por canal (cols Canal/Contatos/Engajados/Engajamento; badge green ≥40%, amber ≥25%, red <25%). GROUP BY origin em 1 query para donut+tabela.
**Testes:** origin null vira "Outros"; engajamento por canal; trendPct.

#### T13 [P] [opus] — Relatório `occurrence` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/occurrence.repository.ts`, `services/occurrence-report.service.ts` · Test: `services/occurrence-report.service.spec.ts`
**Aceitação:** universo = tickets do período com `ocurrence` não-nula/não-vazia. KPIs: total de ocorrências, motivos distintos, % dos tickets com ocorrência, com trendPct. Chart bars: Top-6 motivos. Tabela Top-10 motivos (cols Motivo/Ocorrências/% do total; badge: red se motivo ≥25% do total, amber ≥10%, green <10%). GROUP BY ocurrence em 1 query para gráfico+tabela.
**Testes:** strings vazias excluídas; percentuais somam ≤100; badge nos cortes.

#### T14 [P] [opus] — Relatório `crm` (vendas) (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/crm.repository.ts`, `services/crm-report.service.ts` · Test: `services/crm-report.service.spec.ts`
**Aceitação:** universo de venda = `tickets` (is_sale ∧ status 3/7 ∧ ¬service_not_made) **UNION ALL** `group_tickets` (is_sale ∧ status 3/7), com `CAST(sale_price AS DECIMAL(15,2))`. KPIs: faturamento (brl), vendas fechadas, ticket médio (brl), com trendPct. Chart bars: faturamento por dia/semana (série `a`), vendas não realizadas (`service_not_made=true`) como série `b`. Tabela Top-10 vendedores (attendant; JOIN users; cols Vendedor/Vendas/Receita/Ticket médio; badge por participação na receita: green ≥20%, blue ≥10%, amber <10%). Queries fixas ≤4 (UNION conta como 1).
**Testes:** regra de venda (cada condição); cast de sale_price inválido ("" → 0); ticket médio com 0 vendas → 0.

#### T15 [P] [opus] — Relatório `pix` (L2, depende: T2, T3)
**Arquivos:** Create: `repositories/pix.repository.ts`, `services/pix-report.service.ts` · Test: `services/pix-report.service.spec.ts`
**Aceitação:** universo = `pix_payment` JOIN `tickets` ON ticket_id filtrando `tickets.company_id` (pix_payment NÃO tem company_id — o JOIN é obrigatório). KPIs: volume aprovado (SUM amount, status accepted, brl), transações totais, ticket médio aprovado (brl), com trendPct. Chart bars: volume por dia. Tabela = transações **paginadas** (RF06: única com paginação real; `page`/`pageSize` default 10; cols ID(transaction_id)/Cliente(contato do ticket via JOIN)/Valor/Horário(HH:mm)/Status; badge: accepted→green "Aprovado", pending→amber "Pendente", rejected→red "Rejeitado", expired→red "Expirado"). `table.pagination` preenchido; queries fixas ≤4 + 1 de count.
**Testes:** filtro multi-tenant via JOIN (spec garante companyId no where); paginação (page 2, total); mapa de badges completo.

#### T16 [P] [fast] — Web: PeriodFilter + KpiCard (L2, depende: T1)
**Arquivos:** Create: `src/pages/ReportsV2/components/PeriodFilter/index.tsx`, `src/pages/ReportsV2/components/KpiCard/index.tsx`, styles co-locados
**Aceitação:** PeriodFilter = segmented control `Hoje·7 dias·30 dias·Trimestre` (default 30 dias), ativo com fundo `primary-base`→texto branco, controlado via props. KpiCard recebe `{ label, value, unit, trendPct }` e formata pt-BR (`Intl.NumberFormat('pt-BR')`; brl como moeda; pct com %; trend verde `#16a34a` ↑ / vermelho `#dc2626` ↓, oculto se null) — card radius 18px, borda `rgba(0,0,0,0.06)`, tokens do design.md.
**Testes:** formatação brl/pct/count; trendPct null não renderiza tendência; click muda período.

#### T17 [P] [fast] — Web: BarChart + Donut (recharts) (L2, depende: T1)
**Arquivos:** Create: `src/pages/ReportsV2/components/ReportBarChart/index.tsx`, `src/pages/ReportsV2/components/ReportDonut/index.tsx`
**Aceitação:** wrappers recharts consumindo `chart` do envelope: bars empilhadas (séries a/b) com eixos `#888599` e tooltip escuro `#00000090`; donut com total no centro e legenda lateral (cores vindas do envelope). ResponsiveContainer; sem animação se `prefers-reduced-motion` (prop `isAnimationActive` condicionada a `window.matchMedia`).
**Testes:** render com série vazia não quebra; donut total = soma dos slices; reduced-motion desliga animação.

#### T18 [P] [fast] — Web: DataTable com badges (L2, depende: T1)
**Arquivos:** Create: `src/pages/ReportsV2/components/ReportTable/index.tsx`
**Aceitação:** tabela do envelope (`cols`, `rows.cells`, `badge` na última coluna como pílula radius full/overline com as 4 variantes green/amber/red/blue do handoff mapeadas a tokens semânticos); header uppercase 11.5px/800 muted; hover de linha `gray-100`; contagem "X registros"; quando `pagination` presente, controles anterior/próximo (callback via props). Primeira coluna com avatar circular de iniciais (gradiente da categoria via prop).
**Testes:** render das 4 badges; sem badge não quebra; paginação chama callback.

#### T19 [P] [fast] — Web: DetailDrawer shell (L2, depende: T1)
**Arquivos:** Create: `src/pages/ReportsV2/components/DetailDrawer/index.tsx`
**Aceitação:** drawer fixo à direita `min(720px, 94vw)` com scrim (`rgba(47,32,48,.34)` + blur), slide-in ~0.42s protegido por prefers-reduced-motion; header com ícone 56px no gradiente da categoria, crumb da categoria, título, descrição e botão fechar (40px, hover gira 90° com reduced-motion guard); body scrollável recebendo children; footer com botões Excel/PDF **desabilitados** + Tooltip MUI "Em breve". Fecha por scrim, X e tecla Escape.
**Testes:** Escape fecha; botões de export disabled; children renderizam no body.

#### T20 [P] [fast] — Web: ReportCard + grid do catálogo (L2, depende: T1, T7)
**Arquivos:** Create: `src/pages/ReportsV2/components/ReportCard/index.tsx`, `src/pages/ReportsV2/components/CatalogGrid/index.tsx`
**Aceitação:** card branco radius 18px borda suave SHADOW_MD no hover + translateY(-6px) (reduced-motion guard), ícone 50px com gradiente da categoria (tokens T1), título/descrição/“Abrir relatório →” com hover `primary-base`; `comingSoon` → card com opacidade reduzida, badge "Em breve" (pílula) e não clicável. Grid 4→3→2→1 colunas (1080/820/560px), entrada em cascata (delay por índice, reduced-motion guard). onOpen(reportId) via props.
**Testes:** comingSoon não dispara onOpen; 12 cards renderizam; demais clicáveis chamam onOpen com id.

### Camada L3 — Integração

#### T21 [opus] — Neo: registry + ligação do controller (L3, depende: T8–T15)
**Arquivos:** Edit: `src/modules/reports/reports.module.ts`, `src/modules/reports/controllers/reports.controller.ts` · Create: `src/modules/reports/services/report-registry.ts` · Test: `src/modules/reports/reports.e2e.spec.ts` (ou padrão de integração do repo)
**Aceitação:** registry mapeia os 8 ids → services (DI via módulo); controller resolve e devolve envelope; ids `avgtime|research|agendamento|gagenda` → 501 com mensagem "em breve"; demais desconhecidos → 404. `pnpm vitest:unit` integral verde.
**Testes:** e2e/unit do dispatch: cada id roteia ao service certo; 501 nos 4 futuros; envelope shape validado em 1 relatório real mockando repository.

#### T22 [opus] — Web: página ReportsV2 completa (L3, depende: T6, T7, T16–T20)
**Arquivos:** Create: `src/pages/ReportsV2/index.tsx`, `src/pages/ReportsV2/styles.ts` · Test: `src/pages/ReportsV2/__tests__/index.test.tsx`
**Aceitação:** página com header ("Relatórios" + subtítulo do handoff), CatalogGrid, DetailDrawer aberto via estado; drawer consome `useReportQuery(openId, period)`: loading (skeletons nos KPIs/painéis), erro (mensagem + retry), sucesso renderiza KpiCards + chart (bars/donut conforme envelope) + ReportTable; troca de período refaz a query; pix pagina. Tudo com tokens do design.md; fundo da página `gray-100` com brilhos radiais sutis derivados da marca (sem hex avulsos fora dos tokens/T1).
**Testes:** abre drawer e mostra dados mockados (MSW/mock do service); troca de período dispara refetch; estado de erro renderiza retry.

#### T23 [opus] — Web: alternância por feature flag na rota /reports (L3, depende: T22, e flag das T4/T5)
**Arquivos:** Edit: `src/routes/list.routes.tsx` · Create: `src/pages/ReportsV2/ReportsGate.tsx` · Test: `src/pages/ReportsV2/__tests__/ReportsGate.test.tsx`
**Aceitação:** componente `ReportsGate` usa `useFeatureFlag('relatorios-v2')`: loading → spinner padrão do app; `hasAccess` (ou superAdmin, já coberto pelo hook) → `<ReportsV2/>`; senão → tela legada `<Reports/>` intacta. Rota `/reports` em `list.routes.tsx` passa a renderizar `ReportsGate` (sub-rotas legadas `/reports/*` intocadas). Nenhuma alteração no menu.
**Testes:** flag on → v2; flag off → legada; loading → spinner.

### Camada L4 — Verificação e fechamento

#### T24 [opus] — Auditoria final anti-N+1 / performance (L4, depende: T21)
**Arquivos:** Read-only sobre `src/modules/reports/**` (neo) — correções pontuais se reprovar
**Aceitação:** agente audita TODOS os repositories: zero queries em laço; ranges sargáveis (`>= from AND < to`, nunca função sobre coluna indexada); filtros alinhados aos índices (`company_id` + data; pix via JOIN tickets); agregações no SQL; UNION ALL (não UNION) no crm. Emite relatório por arquivo (aprovado/reprovado + correção). Reprovados são corrigidos e re-auditados.
**Testes:** `pnpm vitest:unit` verde após eventuais correções.

#### T25 [fast] — Neo: Swagger/end-points.yaml + README do módulo (L4, depende: T21)
**Arquivos:** Edit: `end-points.yaml` (via `pnpm openapi:generate` ou script equivalente do repo), `src/modules/reports/README.md`
**Aceitação:** `end-points.yaml` regenerado contém `/reports/{reportId}`; README documenta contrato, períodos, regras de negócio (status/venda/trendPct), os 8 relatórios e a política de performance.
**Testes:** diff do yaml contém a rota nova; lint verde.

#### T26 [fast] — Builds + lint de fechamento (L4, depende: T22, T23, T25)
**Arquivos:** nenhum (verificação)
**Aceitação:** neo `pnpm lint && pnpm vitest:unit && pnpm build` verdes; web `npm run lint && npm run test && npm run build` verdes; api legada `npm run lint` verde. Saídas coladas no relatório da task.
**Testes:** os próprios comandos.

---

## Self-review

1. **Cobertura:** flag+migrations (T4, T5, T23), tela do handoff (T16–T20, T22), dados reais 8 relatórios (T8–T15), envelope RF01 (T2), períodos/trendPct (T3), badges backend RF06 (T8–T15), pix paginado (T15, T18), admin 403 (T2), export desabilitado (T19), design.md (T1 + Context Pack), anti-N+1 (política por task + T24), Swagger/README (T25). Fora: avgtime/research/agendamento/gagenda (501 + "em breve"), export real, paridade numérica formal com legado (PRD critério de amostragem — exige ambiente com dados; ficará para validação manual pós-deploy).
2. **Disjunção [P]:** L1 — arquivos todos distintos (T2 cria módulo, T3 cria util em pasta própria; design.md só na T1). L2 — neo: 1 par repository/service por id; web: pastas de componente distintas; ninguém edita arquivo compartilhado (module/controller só na T21; index.tsx só na T22). ✓
3. **DAG:** L2 depende só de L1; T21←L2(neo); T22←L1/L2(web); T23←T22; L4←L3. Sem dependência intra-camada. ✓
4. **Tiers:** queries com julgamento de SQL/regra de negócio = [opus]; componentes de UI com spec completa do handoff = [fast]; migrations = [fast] (1 arquivo, spec completa). ✓
5. **Verificabilidade:** toda task tem teste nomeado ou comando (T1/T4/T5 verificáveis por inspeção/comando declarado). ✓
