# Configuração da Régua de WhatsApp — Gate G6

Data: 29/10/2026.
Referência: OpenSpec `implementacao-modulo-emprestimos` — Fase 7 (Notificações posteriores — G6).

---

## 1. Provedor e Transporte
- **Provedor Integrado:** `evolution-api` (Evolution API v2 sobre motor Go/Node, container local no Docker do jprOS).
- **Endpoint de Envio:** `POST /message/sendText/:instanceName`.
- **Autenticação:** Header `apikey: <EVOLUTION_API_KEY>`.
- **Isolamento de Contatos:** Os contatos e números de telefone pertencem estritamente ao módulo de empréstimos (`Client.phone`). Não há acoplamento de escrita no CRM nem compartilhamento de conversas externas.

## 2. Remetente e Configuração por Carteira
- Cada carteira possui sua própria instância WhatsApp cadastrada (`instanceName`).
- **Dias de Disparo:** Padrão configurável por carteira:
  - `D-3`: Lembrete antecipado (3 dias antes do vencimento).
  - `D-0`: Lembrete de vencimento no dia.
  - `D+1`, `D+5`, `D+15`: Avisos de atraso com saldo atualizado.
- **Janela de Horário Permitida:** Entre 09:00 e 18:00 (fuso de São Paulo). Disparos fora desse horário são suspensos para evitar incômodo fora do expediente comercial.

## 3. Modelos de Mensagem (Templates)
- **Lembrete Antecipado (D-3):**
  > "Olá {Nome}, lembramos que a parcela {N} do seu contrato de empréstimo vencerá em {Data} no valor de R$ {Valor}."
- **Dia do Vencimento (D-0):**
  > "Olá {Nome}, a parcela {N} do seu contrato de empréstimo vence hoje ({Data}) no valor de R$ {Valor}."
- **Aviso de Atraso (D+N):**
  > "Olá {Nome}, identificamos que a parcela {N} no valor de R$ {Valor} venceu em {Data}. Por favor, entre em contato para regularização."

## 4. Rechecagem de Elegibilidade em Tempo Real (Pré-vôo)
Antes de enviar qualquer mensagem, o serviço executa consulta obrigatória ao banco de dados:
1. Se a parcela já foi quitada (saldo principal zero): **ENVIO SUSPENSO** (`INSTALLMENT_ALREADY_SETTLED`).
2. Se o contrato foi marcado como perda, cancelado ou renegociado: **ENVIO SUSPENSO** (`CONTRACT_INELIGIBLE`).
3. Se o cliente não possuir telefone válido (mínimo 10 dígitos) ou comunicação suspensa: **ENVIO SUSPENSO** (`INVALID_CLIENT_PHONE`).

## 5. Deduplicação e Tratamento de Incerteza
- **Chave Única:** `${walletId}:${contractId}:${installmentId}:${ruleDay}:${scheduledFor}` impede duplicação de itens na fila.
- **Tentativas Limitadas:** Máximo de 3 tentativas para erros recuperáveis de rede.
- **Resultado Incerto / Timeout:** Em caso de timeout de resposta HTTP do provedor, o status é registrado como `uncertain` (`TIMEOUT_RESULT_UNCERTAIN`), **impedindo reenvio cego** que poderia duplicar mensagens para o cliente.
