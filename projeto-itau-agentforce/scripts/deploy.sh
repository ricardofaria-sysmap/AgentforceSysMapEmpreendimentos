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

# Ordem de deploy (respeita dependencias entre componentes):
#   1. objects              (campos, RTs, validation rules, list views, business process)
#   2. dataCategoryGroups   (Knowledge)
#   3. profiles             (categoryGroupVisibilities etc - depende de DCG)
#   4. permissionsets       (dependem dos objects/fields)
#   5. email                (templates usados por Flows/Approval/Workflow)
#   6. classes (Apex)       (referenciadas por Flows, Approval, QuickActions)
#   7. lwc                  (referenciados por FlexiPages/QuickActions)
#   8. tabs                 (dependem dos objects)
#   9. flexipages           (dependem de LWC, tabs, objects)
#  10. applications         (dependem de tabs/flexipages)
#  11. quickActions         (dependem de objects, flows e LWC)
#  12. approvalProcesses    (dependem de fields, email, Apex)
#  13. workflows            (dependem de fields e email)
#  14. flows                (dependem de tudo acima)
#  15-17. genAiPlannerBundles / genAiPlugins / bots (Agentforce - ultimo)

step_counter=0
total_steps=14

run_deploy() {
  local path="$1"
  shift
  local extra_flags=()
  if [ "$#" -gt 0 ]; then
    extra_flags=("$@")
  fi
  step_counter=$((step_counter + 1))
  local step="$step_counter/$total_steps"
  if [ ! -d "$path" ]; then
    echo ""
    echo "==> [$step] $path - pulando (nao existe)"
    return 0
  fi
  if ! compgen -G "$path/*" > /dev/null; then
    echo ""
    echo "==> [$step] $path - pulando (vazio)"
    return 0
  fi
  echo ""
  echo "==> [$step] $path"
  sf project deploy start \
    -o "$ORG_ALIAS" \
    -d "$path" \
    --ignore-conflicts \
    ${extra_flags[@]+"${extra_flags[@]}"} \
    ${DEPLOY_FLAGS[@]+"${DEPLOY_FLAGS[@]}"}
}

run_deploy "force-app/main/default/objects"
run_deploy "force-app/main/default/dataCategoryGroups"
run_deploy "force-app/main/default/profiles"
run_deploy "force-app/main/default/permissionsets"
run_deploy "force-app/main/default/email"
run_deploy "force-app/main/default/classes" \
  --test-level RunSpecifiedTests \
  --tests FeriasEmailSenderTest \
  --tests FeriasApprovalSubmitterTest
run_deploy "force-app/main/default/lwc"
run_deploy "force-app/main/default/tabs"
run_deploy "force-app/main/default/flexipages"
run_deploy "force-app/main/default/applications"
run_deploy "force-app/main/default/quickActions"
run_deploy "force-app/main/default/approvalProcesses"
run_deploy "force-app/main/default/workflows"
run_deploy "force-app/main/default/flows"

# Agentforce (opcional — so existe depois de criar via UI e rodar retrieve-agent.sh)
total_steps=17
run_deploy "force-app/main/default/genAiPlannerBundles"
run_deploy "force-app/main/default/genAiPlugins"
run_deploy "force-app/main/default/bots"

echo ""
echo "$LABEL concluido."
if [ "$LABEL" = "DRY-RUN (validacao sem persistir)" ]; then
  echo "Nenhuma alteracao foi feita na org. Remova --dry-run para persistir."
else
  echo "Proximos passos:"
  echo "  1. ./scripts/create-users.sh $ORG_ALIAS"
  echo "  2. ./scripts/bootstrap-data.sh $ORG_ALIAS"
  echo "  3. ./scripts/load-feriados.sh $ORG_ALIAS"
  echo "  4. ./scripts/create-knowledge.sh $ORG_ALIAS   # publica os 5 artigos de politica"
  echo "  5. Criar Agent_Itau_RH via Agent Builder UI - ver docs/AGENT.md (5 min)"
  echo "  6. ./scripts/retrieve-agent.sh $ORG_ALIAS    # versiona o agent no SFDX project"
fi
