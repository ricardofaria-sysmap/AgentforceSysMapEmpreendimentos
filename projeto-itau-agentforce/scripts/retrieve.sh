#!/usr/bin/env bash
# retrieve.sh — puxa componentes Agentforce/Flow/Approval criados via UI para o repo
# Uso: ./scripts/retrieve.sh <alias-da-org>

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"

echo "==> Puxando componentes da org $ORG_ALIAS"

sf project retrieve start \
  -o "$ORG_ALIAS" \
  -m "Flow:Agendamento_Ferias_Screen" \
  -m "Flow:Case_Ferias_Aprovado_Pos" \
  -m "ApprovalProcess:Case.Aprovacao_Pedido_Ferias" \
  -m "Bot:Itau_RH_Agent" \
  -m "GenAiPlanner" \
  -m "GenAiPlugin" \
  -m "GenAiFunction" \
  -m "MessagingChannel:Itau_Employee_Chat" \
  -m "EmbeddedServiceConfig:Itau_RH_Portal" \
  -m "Knowledge__kav"

echo ""
echo "Retrieve concluido. Revise git status antes de commitar."
