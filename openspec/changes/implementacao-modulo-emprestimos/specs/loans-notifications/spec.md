# Spec Delta

## Purpose

Permitir avisos automáticos de empréstimos por WhatsApp com regras e destinatários controlados por carteira.

## ADDED Requirements

### Requirement: Configuração de avisos por carteira
O sistema MUST permitir configurar dias de aviso automático por WhatsApp em cada carteira autorizada; a capacidade é posterior e não bloqueia o núcleo operacional.

#### Scenario: Carteiras com regras diferentes
- **WHEN** duas carteiras configuram dias de aviso diferentes
- **THEN** os avisos de cada carteira seguem apenas suas próprias regras e destinatários

### Requirement: Conferência antes do envio
O sistema MUST verificar elegibilidade, saldo, vencimento, contato e situação atual antes de enviar uma notificação.

#### Scenario: Parcela quitada antes do envio
- **WHEN** uma parcela é quitada, cancelada, substituída ou marcada como perda antes de um aviso programado
- **THEN** o aviso não é enviado

### Requirement: Recuperação e envio incerto
O sistema MUST preservar histórico de tentativas, limitar repetições e tratar resultado incerto sem prometer entrega exatamente uma vez.

#### Scenario: Tempo esgotado após tentativa
- **WHEN** o provedor pode ter aceitado a mensagem mas a confirmação não chega
- **THEN** o sistema registra resultado incerto e não reenvia cegamente

#### Scenario: Contato inválido
- **WHEN** o destinatário não tem contato válido ou está bloqueado para comunicação
- **THEN** o sistema não envia o aviso e apresenta a razão operacional
