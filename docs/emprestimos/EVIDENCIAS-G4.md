# Evidências de Indicadores, Relatórios e Exportação — Gate G4

Data de consolidação: 29/10/2026.
Referência: OpenSpec `implementacao-modulo-emprestimos`, Seção 5 (Indicadores e relatórios — G4), DT-03.

## 1. Indicadores K1 a K8 Conciliados
- **K1 — Principal Contratual em Aberto:**
  - Soma o saldo remanescente de principal dos contratos confirmados ativos (`state: 'confirmed'`).
  - O saldo em perda é segregado explicitamente (`k1Loss`), não compondo o principal ativo regular (`k1Active`).
- **K2 — A Receber em 30 Dias:**
  - Considera parcelas abertas de contratos ativos com vencimento entre a data de corte $asOf$ e $asOf + 30\text{ dias}$.
  - Soma principal e juros contratuais vincendos, excluindo encargos moratórios futuros.
- **K3 — Vencido por Faixa de Atraso:**
  - Classificação em 4 faixas: 1–7 dias, 8–30 dias, 31–90 dias e mais de 90 dias.
  - Exibe saldo vencido total, quantidade de parcelas e quantidade de clientes únicos em cada faixa.
- **K4 — Carteira em Risco (PAR 30):**
  - Quociente do principal total (K1) dos contratos com qualquer parcela em atraso superior a 30 dias dividido pelo K1 total da carteira.
  - Denominador zero ($K1_{total} = 0$) retorna `null` ("N/A"), sem erro de divisão por zero.
- **K5 — Efetividade de Cobrança do Mês:**
  - Numerador: caixa alocado a principal e juros das parcelas com vencimento no mês corrente.
  - Denominador: valor exigível contratual dessas parcelas antes de descontos.
  - Multas e mora não entram no numerador; descontos concedidos são reportados separadamente.
- **K6 — Juros Contratuais Recebidos no Mês:**
  - Alocações líquidas de juros recebidos no mês civil de referência.
  - Multas e juros de mora reportados separadamente.
  - Nunca denominado "lucro líquido".
- **K7 — Retorno Bruto (Juros Recebidos / Principal Médio):**
  - Quociente de K6 pela média dos saldos diários de principal no mês até a data de corte.
- **K8 — Concentração (Top 10 Clientes):**
  - Participação do principal dos 10 maiores clientes no principal total ativo da carteira.

## 2. Qualidade dos Dados e Sinalização de Estimativas
- Pagamentos históricos cadastrados com data estimada (`estimated: true`) são contabilizados e informados com o indicador `hasEstimatedDates`.
- O percentual de cobertura exata da base é explicitado no painel (`quality.coveragePercent`).

## 3. Relatórios Operacionais e Fluxo de Caixa (6 Meses)
- O fluxo de caixa dos últimos 6 meses separa rigorosamente:
  - **Novas Concessões:** Desembolso real de capital em contratos novos.
  - **Renegociações (Acordos):** Volume renegociado informado separadamente, garantindo que a novação de dívida não seja computada como saída de caixa real nem gere recebimento fictício na origem.
  - **Recebimentos Reais:** Decompostos em principal, juros contratuais e encargos (multa/mora).
- Relatório de Distribuição de Contratos por Situação (Ativo, Em atraso, Em perda, Quitado, Renegociado, Cancelado).
- Relatório de Maiores Devedores com contratos abertos, saldo devedor, saldo vencido e dias de atraso.

## 4. Exportação e Proteção LGPD / Formula Injection
- **Proteção Contra Formula Injection (CSV/Excel):** Todos os campos de texto iniciados por `=`, `+`, `-`, `@`, `\t` ou `\r` são automaticamente prefixados com apóstrofo (`'`) pelo `sanitizeCsvField`, neutralizando execução de macros/DDE em leitores de planilhas.
- **Mascaramento LGPD:** Documentos de clientes (CPF) são mascarados no padrão `***.***.123-**` em todas as consultas públicas e exportações.
- **Isolamento de Carteira:** Acesso a indicadores e exportações restrito à carteira do membro autenticado, retornando `404 NOT_FOUND` em acessos cruzados.

## 5. Testes Automatizados Comprovados
- `evo-loans-service/test/reports-and-indicators.test.mjs`: Testes do cálculo independente de K1-K8, segregação de perda, qualidade de base, formula injection e mascaramento de CPF.
- `evo-ai-frontend-community/src/pages/loans/LoansDashboard.spec.tsx`: Testes de renderização dos indicadores K1 a K8, alerta de datas estimadas e tratamento de denominador zero ("N/A").
- `evo-ai-frontend-community/src/pages/loans/LoansReports.spec.tsx`: Testes do fluxo de 6 meses, distribuições, maiores devedores e disparo de exportação CSV.
