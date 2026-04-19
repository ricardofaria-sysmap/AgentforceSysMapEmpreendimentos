#!/usr/bin/env bash
# retrieve-agent.sh - apos criar o Agent_Itau_RH via Agent Builder UI,
# baixa o metadata para o SFDX project, versionando no git.
#
# Uso: ./scripts/retrieve-agent.sh <alias-da-org>
#
# Pre-requisito:
#   - Criar o agent "Agent Itau RH" (api-name Agent_Itau_RH) via UI seguindo docs/AGENT.md
#
# Idempotente: roda novamente quando alterar o agent na UI para atualizar os XMLs locais.

set -euo pipefail

ORG_ALIAS="${1:-itau-demo}"
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
PKG_TMP="$(mktemp -d)"

trap "rm -rf $PKG_TMP" EXIT

cat > "$PKG_TMP/package.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Agent_Itau_RH</members>
        <name>Bot</name>
    </types>
    <types>
        <members>Agent_Itau_RH</members>
        <name>GenAiPlannerBundle</name>
    </types>
    <types>
        <members>*</members>
        <name>GenAiPlugin</name>
    </types>
    <version>66.0</version>
</Package>
EOF

echo "==> Baixando metadata do agent Agent_Itau_RH da org $ORG_ALIAS"
cd "$WORKDIR"
sf project retrieve start -o "$ORG_ALIAS" -x "$PKG_TMP/package.xml"

echo ""
echo "==> Arquivos baixados:"
find force-app/main/default/bots force-app/main/default/genAiPlannerBundles force-app/main/default/genAiPlugins -type f 2>/dev/null | sort

echo ""
echo "OK! Agent metadata versionado. Commit com: git add force-app/main/default/{bots,genAiPlannerBundles,genAiPlugins}"
