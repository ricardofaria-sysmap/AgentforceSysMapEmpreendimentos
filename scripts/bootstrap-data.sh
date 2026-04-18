#!/usr/bin/env bash
# bootstrap-data.sh — cria os 3 registros Saldo_Ferias__c para as personas.
# Uso: ./scripts/bootstrap-data.sh <alias-da-org>
#
# Le scripts/.usernames.env (gerado por create-users.sh).

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAMES_FILE="$SCRIPT_DIR/.usernames.env"

if [ ! -f "$USERNAMES_FILE" ]; then
  echo "ERRO: $USERNAMES_FILE nao encontrado. Rode ./scripts/create-users.sh $ORG_ALIAS primeiro."
  exit 1
fi
# shellcheck disable=SC1090
source "$USERNAMES_FILE"

echo "==> Populando Saldo_Ferias__c na org $ORG_ALIAS"
echo "  Marina = $MARINA_USERNAME"
echo "  Pedro  = $PEDRO_USERNAME"
echo "  Carlos = $CARLOS_USERNAME"

get_user_id() {
  sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM User WHERE Username='$1' LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty'
}

MARINA_ID=$(get_user_id "$MARINA_USERNAME")
PEDRO_ID=$(get_user_id "$PEDRO_USERNAME")
CARLOS_ID=$(get_user_id "$CARLOS_USERNAME")

for id in "$MARINA_ID" "$PEDRO_ID" "$CARLOS_ID"; do
  if [ -z "$id" ]; then
    echo "ERRO: algum user nao foi localizado na org. Rode create-users.sh antes."
    exit 1
  fi
done

echo ""
echo "  Marina.Id = $MARINA_ID"
echo "  Pedro.Id  = $PEDRO_ID"
echo "  Carlos.Id = $CARLOS_ID"

create_saldo_if_absent() {
  local user_id="$1" regime="$2" inicio="$3" faltas="$4" tirados="$5" label="$6"

  local existing
  existing=$(sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM Saldo_Ferias__c WHERE Colaborador__c='$user_id' AND Periodo_Aquisitivo_Inicio__c=$inicio LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty')
  if [ -n "$existing" ]; then
    echo "  (ja existe: $label -> $existing)"
    return
  fi

  echo "  Criando: $label"
  sf data create record -o "$ORG_ALIAS" -s Saldo_Ferias__c \
    -v "Colaborador__c=$user_id Regime_Contratacao__c=$regime Periodo_Aquisitivo_Inicio__c=$inicio Faltas_Injustificadas__c=$faltas Dias_Tirados__c=$tirados Dias_Abono_Vendidos__c=0 Status__c=Vigente" >/dev/null
}

echo ""
echo "==> Criando saldos"
create_saldo_if_absent "$MARINA_ID" "CLT" "2025-03-01" "2" "0"  "Saldo Marina CLT 2025 (saldo cheio, 2 faltas)"
create_saldo_if_absent "$PEDRO_ID"  "PJ"  "2025-01-15" "0" "5"  "Saldo Pedro PJ 2025 (20 dias PJ, 5 ja tirados)"
create_saldo_if_absent "$CARLOS_ID" "CLT" "2024-11-01" "0" "20" "Saldo Carlos CLT 2024 (perto do limite)"

echo ""
echo "==> Validacao"
sf data query -o "$ORG_ALIAS" \
  -q "SELECT Name, Colaborador__r.Name, Regime_Contratacao__c, Dias_Direito__c, Dias_Tirados__c, Dias_Disponiveis__c, Status__c FROM Saldo_Ferias__c WHERE Colaborador__r.Username IN ('$MARINA_USERNAME','$PEDRO_USERNAME','$CARLOS_USERNAME') ORDER BY Colaborador__r.Name"
