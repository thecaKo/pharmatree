# Exemplo de daily preenchida pela IA

Referência de tom/altura ao sintetizar `daily/AAAA-MM-DD.md`. Não copie literal —
adapte ao que estiver em `raw/`.

```markdown
---
type: daily
data: 2026-06-09
---

# 2026-06-09 (terça)

## Plano (a fazer)

1. **Destravar [[frentes/atendimentos-v2|Atendimentos V2]]** — card "Tickets Normais
   e Grupos" voltou como _Teste reprovado_ (Alta). Ver [[impedimentos/atendimentos-v2-reprovado-jennifer]].
2. Avançar no "Agente para buscar produtos por arquivo/conexão direta" (Em Atividade, resp.).
3. Acompanhar como par: itens de encarte (rodapé, cor da caixa de preço).

_Fonte: raw/2026-06-09/monday.json (overview modo início)._

## Feito

- `web-pharmachatbot [feat/atendimentos-v2-reborn]`: ajuste no carregamento da
  listagem de tickets — `a1b2c3d`. _(raw/2026-06-09/git.md)_
- Investigado motivo da reprovação do card de Atendimentos V2. _(relato + Monday)_

## Impedimentos

- [[impedimentos/atendimentos-v2-reprovado-jennifer]] — 18 bugs no teste da QA;
  suspeita de causa estrutural (flag/conexão no ambiente de teste), não 18 bugs isolados.

## Decisões / Aprendizados

- Tratar a reprovação como 1 problema de ambiente antes de abrir 18 sub-tarefas.

## Para a daily de amanhã

- **Fiz:** investiguei a reprovação do Atendimentos V2 e comecei o fix da listagem.
- **Vou fazer:** validar conexão/flag no ambiente de teste e devolver o card pra QA.
- **Travado em:** confirmar se carrinho Trier e Pix funcionam na V2 (dúvida da QA).
```
