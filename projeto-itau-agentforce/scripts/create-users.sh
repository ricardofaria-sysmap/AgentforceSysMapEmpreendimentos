#!/usr/bin/env bash
# create-users.sh — cria as 3 personas da demo em Developer Edition (ou scratch)
# via `sf data create record -s User`, atribui permission sets e hierarquia.
# Uso: ./scripts/create-users.sh <alias-da-org>
#
# Gera um arquivo scripts/.usernames.env com as usernames calculadas
# (usadas tambem por bootstrap-data.sh).

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAMES_FILE="$SCRIPT_DIR/.usernames.env"

echo "==> Org: $ORG_ALIAS"

ORG_ID=$(sf org display -o "$ORG_ALIAS" --json | jq -r '.result.id')
SUFFIX=$(echo "$ORG_ID" | tr '[:upper:]' '[:lower:]' | cut -c1-15)
echo "==> Sufixo de domain: .$SUFFIX"

PROFILE_ID=$(sf data query -o "$ORG_ALIAS" \
  -q "SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1" \
  --json | jq -r '.result.records[0].Id')

if [ -z "$PROFILE_ID" ] || [ "$PROFILE_ID" = "null" ]; then
  echo "ERRO: Profile 'Standard User' nao encontrado na org."
  exit 1
fi
echo "==> ProfileId Standard User = $PROFILE_ID"

CARLOS_USERNAME="carlos.gestor@itau.demo.${SUFFIX}.local"
MARINA_USERNAME="marina.colaboradora@itau.demo.${SUFFIX}.local"
PEDRO_USERNAME="pedro.colaborador@itau.demo.${SUFFIX}.local"

get_user_id() {
  sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM User WHERE Username='$1' LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty'
}

create_user() {
  local username="$1" first="$2" last="$3" alias="$4" title="$5" dept="$6" fed="$7"
  local existing
  existing=$(get_user_id "$username")
  if [ -n "$existing" ]; then
    echo "  (ja existe: $existing)" >&2
    echo "$existing"
    return
  fi

  sf data create record -o "$ORG_ALIAS" -s User \
    -v "Username=$username Email=$username Alias=$alias FirstName=$first LastName='$last' ProfileId=$PROFILE_ID TimeZoneSidKey=America/Sao_Paulo LocaleSidKey=pt_BR LanguageLocaleKey=pt_BR EmailEncodingKey=UTF-8 Title='$title' Department=$dept FederationIdentifier=$fed" >&2

  get_user_id "$username"
}

echo ""
echo "-- Carlos (Gestor)"
CARLOS_ID=$(create_user "$CARLOS_USERNAME" "Carlos" "Gestor" "cgest" "Coordenador RH" "Tecnologia" "IT-GST-001")
echo "  Carlos.Id = $CARLOS_ID"

echo ""
echo "-- Marina (CLT)"
MARINA_ID=$(create_user "$MARINA_USERNAME" "Marina" "Colaboradora CLT" "mcltd" "Analista Pleno" "Tecnologia" "IT-CLT-001")
echo "  Marina.Id = $MARINA_ID"

echo ""
echo "-- Pedro (PJ)"
PEDRO_ID=$(create_user "$PEDRO_USERNAME" "Pedro" "Colaborador PJ" "pcolpj" "Consultor PJ" "Tecnologia" "IT-PJ-001")
echo "  Pedro.Id = $PEDRO_ID"

echo ""
echo "==> Atribuindo Permission Sets"

assign_permset() {
  local user_id="$1" permset_name="$2"
  local existing
  existing=$(sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM PermissionSetAssignment WHERE AssigneeId='$user_id' AND PermissionSet.Name='$permset_name' LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty')
  if [ -n "$existing" ]; then
    echo "  (ja atribuido: $permset_name)"
    return
  fi
  local psid
  psid=$(sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM PermissionSet WHERE Name='$permset_name' LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty')
  if [ -z "$psid" ]; then
    echo "  AVISO: permset $permset_name nao encontrado na org, pulando."
    return
  fi
  sf data create record -o "$ORG_ALIAS" -s PermissionSetAssignment \
    -v "AssigneeId=$user_id PermissionSetId=$psid"
}

assign_permset "$CARLOS_ID" "Agentforce_RH_Gestor"
assign_permset "$MARINA_ID" "Agentforce_RH_Colaborador"
assign_permset "$PEDRO_ID"  "Agentforce_RH_Colaborador"

echo ""
echo "==> Hierarquia (Carlos como manager de Marina e Pedro)"
sf data update record -o "$ORG_ALIAS" -s User -i "$MARINA_ID" -v "ManagerId=$CARLOS_ID" >/dev/null
echo "  Marina.ManagerId = $CARLOS_ID"
sf data update record -o "$ORG_ALIAS" -s User -i "$PEDRO_ID"  -v "ManagerId=$CARLOS_ID" >/dev/null
echo "  Pedro.ManagerId  = $CARLOS_ID"

cat > "$USERNAMES_FILE" <<EOF
# gerado por create-users.sh — usado por bootstrap-data.sh
CARLOS_USERNAME=$CARLOS_USERNAME
MARINA_USERNAME=$MARINA_USERNAME
PEDRO_USERNAME=$PEDRO_USERNAME
EOF
echo ""
echo "==> Usernames salvas em $USERNAMES_FILE"
echo ""
echo "Setup de senhas (opcional):"
echo "  sf org reset password -o $ORG_ALIAS -b $CARLOS_USERNAME"
echo "  sf org reset password -o $ORG_ALIAS -b $MARINA_USERNAME"
echo "  sf org reset password -o $ORG_ALIAS -b $PEDRO_USERNAME"
echo ""
echo "Ou acesse Setup > Users na UI e clique 'Reset Password' em cada persona."
