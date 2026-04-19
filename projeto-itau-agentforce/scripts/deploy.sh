#!/usr/bin/env bash
# deploy.sh — bootstrap completo da demo Agentforce RH Itau
# Uso:
#   ./scripts/deploy.sh <alias-da-org> [--dry-run]
# Exemplos:
#   ./scripts/deploy.sh AgentforceSysmapEmpreendimentos --dry-run
#   ./scripts/deploy.sh itau-demo

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
MODE="${2:-}"

DEPLOY_FLAGS=()
LABEL="DEPLOY"
if [ "$MODE" = "--dry-run" ] || [ "$MODE" = "-c" ]; then
  DEPLOY_FLAGS+=(--dry-run)
  LABEL="DRY-RUN (validacao sem persistir)"
fi

echo "==> Alvo: $ORG_ALIAS"
echo "==> Modo: $LABEL"
sf org display -o "$ORG_ALIAS" --json > /dev/null || {
  echo "Org $ORG_ALIAS nao autenticada. Rode: sf org login web -a $ORG_ALIAS"
  exit 1
}

run_deploy() {
  local step="$1"
  local path="$2"
  echo ""
  echo "==> [$step] $path"
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d "$path" \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
}

run_deploy "1/5" "force-app/main/default/objects"
if [ -d force-app/main/default/dataCategoryGroups ]; then
  run_deploy "2/5" "force-app/main/default/dataCategoryGroups"
else
  echo "==> [2/5] Sem dataCategoryGroups - pulando"
fi
run_deploy "3/5" "force-app/main/default/permissionsets"
run_deploy "4/5" "force-app/main/default/email"

echo ""
echo "==> [5/5] Flows, Apex classes e Agent (se presentes)"
if compgen -G "force-app/main/default/classes/*.cls" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/classes \
    --ignore-conflicts \
    --test-level RunSpecifiedTests --tests FeriasEmailSenderTest --tests FeriasApprovalSubmitterTest \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
fi
if compgen -G "force-app/main/default/flows/*.flow-meta.xml" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/flows \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
else
  echo "  (sem flows versionados ainda - crie na UI e rode retrieve.sh)"
fi

if [ -d force-app/main/default/genAiPlannerBundles ] && compgen -G "force-app/main/default/genAiPlannerBundles/*" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/genAiPlannerBundles \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
fi
if [ -d force-app/main/default/genAiPlugins ] && compgen -G "force-app/main/default/genAiPlugins/*" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/genAiPlugins \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
fi
if [ -d force-app/main/default/bots ] && compgen -G "force-app/main/default/bots/*" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/bots \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
else
  echo "  (sem agent versionado ainda - crie via UI seguindo docs/AGENT.md e rode scripts/retrieve-agent.sh)"
fi

echo ""
echo "$LABEL concluido."
if [ "$LABEL" = "DRY-RUN (validacao sem persistir)" ]; then
  echo "Nenhuma alteracao foi feita na org. Remova --dry-run para persistir."
else
  echo "Proximos passos:"
  echo "  1. ./scripts/create-users.sh $ORG_ALIAS"
  echo "  2. ./scripts/bootstrap-data.sh $ORG_ALIAS"
  echo "  3. ./scripts/create-knowledge.sh $ORG_ALIAS   # publica os 5 artigos de politica"
  echo "  4. Criar Agent_Itau_RH via Agent Builder UI - ver docs/AGENT.md (5 min)"
  echo "  5. ./scripts/retrieve-agent.sh $ORG_ALIAS   # versiona o agent no SFDX project"
fi
