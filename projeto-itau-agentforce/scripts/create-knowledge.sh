#!/usr/bin/env bash
# create-knowledge.sh — cria e publica os 5 artigos de Knowledge do Itau.
# Uso: ./scripts/create-knowledge.sh <alias-da-org>
#
# Pre-requisitos (ja cobertos pelo deploy):
#   - Knowledge ativado na org (Setup > Knowledge Settings)
#   - RecordType Knowledge__kav.Politica_RH deployado
#   - DataCategoryGroup Topicos_RH com categorias Ferias/Beneficios/Home_Office
#   - Custom fields Politica_Conteudo__c, Politica_Fonte_Legal__c, Politica_Ultima_Revisao__c
#
# Idempotente: artigos com UrlName ja publicado (Online) em pt_BR sao pulados.

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APEX_FILE="$SCRIPT_DIR/apex/create-knowledge.apex"

if [ ! -f "$APEX_FILE" ]; then
  echo "ERRO: $APEX_FILE nao encontrado."
  exit 1
fi

echo "==> Publicando artigos de Knowledge na org $ORG_ALIAS"
sf apex run -o "$ORG_ALIAS" -f "$APEX_FILE"

echo ""
echo "==> Validacao: artigos publicados (Online/pt_BR)"
sf data query -o "$ORG_ALIAS" \
  -q "SELECT UrlName, Title, PublishStatus, Language FROM Knowledge__kav WHERE PublishStatus='Online' AND Language='pt_BR' AND RecordType.DeveloperName='Politica_RH' ORDER BY UrlName"

echo ""
echo "OK! Knowledge pronto para ser consumido pelo Agente A."
