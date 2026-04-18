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

run_deploy "1/4" "force-app/main/default/objects"
run_deploy "2/4" "force-app/main/default/permissionsets"
run_deploy "3/4" "force-app/main/default/email"

echo ""
echo "==> [4/4] Flows e Agent (se presentes)"
if compgen -G "force-app/main/default/flows/*.flow-meta.xml" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/flows \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
else
  echo "  (sem flows versionados ainda - crie na UI e rode retrieve.sh)"
fi

if [ -d force-app/main/default/bots ] && compgen -G "force-app/main/default/bots/*" > /dev/null; then
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d force-app/main/default/bots \
    --ignore-conflicts \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
else
  echo "  (sem agent versionado ainda - crie na UI e rode retrieve.sh)"
fi

echo ""
echo "$LABEL concluido."
if [ "$LABEL" = "DRY-RUN (validacao sem persistir)" ]; then
  echo "Nenhuma alteracao foi feita na org. Remova --dry-run para persistir."
else
  echo "Proximos passos:"
  echo "  1. ./scripts/create-users.sh $ORG_ALIAS"
  echo "  2. ./scripts/bootstrap-data.sh $ORG_ALIAS"
  echo "  3. Criar Approval Process, Knowledge e Agent via UI (ver force-app/README.md)"
fi
