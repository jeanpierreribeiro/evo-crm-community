# Critérios e Formalização dos Indicadores K1–K8 e Débito DT-03

Data de consolidação: 29/10/2026.
Referência: OpenSpec `implementacao-modulo-emprestimos`, Seção de Indicadores-chave, DT-03 e Gates G4/G5.

## 1. Fechamento do DT-03: Princípios e Regras de Negócio

O débito técnico DT-03 estabelece a necessidade de formalizar a matemática e o tratamento contábil/financeiro dos indicadores sem distorcer o fluxo de caixa, sem criar transferências fictícias e sem inflar resultados.

### 1.1 Segregação entre Dívida em Cobrança e Dívida em Perda
- **Contratos Marcados como Perda (`state: 'loss'`):**
  - O saldo devedor congelado em perda NÃO é considerado quitado nem perdoado tacitamente.
  - No cálculo do Principal em Aberto (K1), o saldo em perda é segregado e exibido explicitamente como indicador complementar (`k1Loss`), não compondo o principal ativo regular (`k1Active`).
  - Dessa forma, uma dívida em perda não polui o capital operacional em giro nem mascara inadimplência como quitação.

### 1.2 Recuperações de Perda
- Quando ocorre recuperação em contrato em perda:
  - O valor recebido amortiza os componentes pela ordem estrita: Multa congelada $\rightarrow$ Juros contratuais congelados $\rightarrow$ Mora $\rightarrow$ Principal.
  - A recuperação amortiza o saldo em perda remanescente.
  - A parcela alocada a juros ou encargos é registrada como **Receita de Recuperação de Crédito**, entrando em K6 com identificação específica.

### 1.3 Renegociações e Acordos
- A novação ou prorrogação para novo acordo encerra a cobrança do contrato de origem e gera um contrato de destino:
  - **Fluxo de Caixa:** NÃO há desembolso de novo caixa nem recebimento fictício na origem.
  - **Relatórios Operacionais:** O principal do novo acordo é classificado como originado de novação/acordo e segregado de concessões de dinheiro novo.

### 1.4 Correções Retroativas e Estornos
- **Estorno de Recebimento:**
  - Desfaz a alocação aos componentes via ajuste compensatório positivo.
  - Em K6 (juros recebidos no mês), estornos ocorridos no mês abatem os juros recebidos do mês.
- **Correção de Data Efetiva:**
  - Registrada via `LoanPaymentDateCorrection` com motivo auditado.
  - O indicador de qualidade dos dados reporta a contagem de registros com data corrigida ou estimada.

---

## 2. Especificação Matemática dos Indicadores K1 a K8

| Indicador | Nome | Fórmula / Definição | Tratamento de Exceções |
| :--- | :--- | :--- | :--- |
| **K1** | Principal Contratual em Aberto | $\sum (Principal_{previsto} + Ajustes_{principal} - Amortizações_{líquidas})$ dos contratos confirmados ativos | Contratos em perda são segregados em `k1Loss`. |
| **K2** | A Receber em 30 Dias | Soma do principal + juros contratuais das parcelas abertas com vencimento em $[Hoje, Hoje + 30\text{ dias}[$ | Exclui multas/mora vincendas e contratos em perda. |
| **K3** | Vencido por Faixa de Atraso | Saldo das parcelas vencidas em 1-7, 8-30, 31-90 e >90 dias, com contagem de parcelas e clientes | Baseada na data de referência $asOf$. |
| **K4** | Carteira em Risco (PAR 30) | $\frac{K1 \text{ dos contratos com alguma parcela vencida há } > 30 \text{ dias}}{K1 \text{ total}}$ | Se $K1 \text{ total} = 0$, retorna `null` ("N/A"). |
| **K5** | Efetividade de Cobrança do Mês | $\frac{\text{Caixa alocado a principal + juros contratuais das parcelas vencidas no mês}}{\text{Exigível dessas parcelas no mês antes dos descontos}}$ | Multa/mora não entram no numerador. Se exigível = 0, retorna `null` ("N/A"). |
| **K6** | Juros Contratuais Recebidos no Mês | Alocações líquidas de juros contratuais no mês de referência (menos estornos) | Não denominado lucro líquido. Multa e mora separadas. |
| **K7** | Juros Recebidos / Principal Médio | $\frac{K6}{\text{Média dos saldos diários de principal no mês até } asOf}$ | Retorno bruto observado. Denominador zero retorna `null`. |
| **K8** | Concentração da Carteira | $\frac{K1 \text{ dos 10 maiores clientes}}{K1 \text{ total}}$ | Se $K1 \text{ total} = 0$, retorna `null` ("N/A"). |

---

## 3. Qualidade dos Dados e Cobertura
- **Sinalização de Estimativas:** Lançamentos históricos manuais com data estimada (`estimated: true`) são contabilizados e informados com o indicador `hasEstimatedDates` e percentual de cobertura.
- **Denominador Zero:** Tratado como `null` ("Não Aplicável"), evitando erros de divisão por zero ou infinitos artificiais.
- **Segurança e LGPD na Exportação:** Todos os relatórios aplicam sanitização contra injeção de fórmulas CSV (prefixando `'` em células iniciadas por `=`, `+`, `-`, `@`) e mascaramento de CPF.
