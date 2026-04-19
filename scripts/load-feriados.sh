#!/usr/bin/env bash
# load-feriados.sh — importa feriados nacionais 2026 para Feriado__c.
# Uso: ./scripts/load-feriados.sh <alias-da-org>
# Idempotente: usa upsert por (Name + Data__c) via SOQL lookup.

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$SCRIPT_DIR/../data/feriados-2026.csv"

if [ ! -f "$CSV_FILE" ]; then
  echo "ERRO: $CSV_FILE nao encontrado"
  exit 1
fi

echo "==> Carregando feriados em $ORG_ALIAS"

# Pula o cabecalho
tail -n +2 "$CSV_FILE" | while IFS=',' read -r name data tipo; do
  name=$(echo "$name" | tr -d '\r')
  data=$(echo "$data" | tr -d '\r')
  tipo=$(echo "$tipo" | tr -d '\r')

  existing=$(sf data query -o "$ORG_ALIAS" \
    -q "SELECT Id FROM Feriado__c WHERE Name='$name' AND Data__c=$data LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty')

  if [ -n "$existing" ]; then
    echo "  (existe: $name / $data)"
  else
    echo "  criando: $name / $data / $tipo"
    sf data create record -o "$ORG_ALIAS" -s Feriado__c \
      -v "Name='$name' Data__c=$data Tipo__c=$tipo" >/dev/null
  fi
done

echo ""
echo "==> Validacao"
sf data query -o "$ORG_ALIAS" \
  -q "SELECT Name, Data__c, Tipo__c FROM Feriado__c WHERE Ano__c IN (2026, 2027) ORDER BY Data__c"
