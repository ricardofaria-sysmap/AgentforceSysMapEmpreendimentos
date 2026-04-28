#!/bin/bash
# Test C1 Backend Verification Script
# Run this AFTER executing the manual test with Marina

MARINA_USER_ID="005Hp00000n0ej3IAA"

echo "==========================================="
echo "Test C1 Backend Verification"
echo "User: Marina Colaboradora CLT"
echo "User ID: $MARINA_USER_ID"
echo "==========================================="
echo ""

# 1. Check latest Case
echo "1. Querying latest Case created by Marina..."
sf data query --query "SELECT Id, CaseNumber, Subject, Status, Data_Inicio_Ferias__c, Data_Retorno_Ferias__c, Vender_Abono__c, Dias_Abono__c, Aprovacao_Gestor__c, OwnerId, Gestor__c, Origin, CreatedDate FROM Case WHERE OwnerId = '$MARINA_USER_ID' ORDER BY CreatedDate DESC LIMIT 1" --json > /tmp/test-c1-case.json

CASE_ID=$(cat /tmp/test-c1-case.json | jq -r '.result.records[0].Id // "NOT_FOUND"')
CASE_NUMBER=$(cat /tmp/test-c1-case.json | jq -r '.result.records[0].CaseNumber // "NOT_FOUND"')
DATA_INICIO=$(cat /tmp/test-c1-case.json | jq -r '.result.records[0].Data_Inicio_Ferias__c // "NOT_FOUND"')
DATA_RETORNO=$(cat /tmp/test-c1-case.json | jq -r '.result.records[0].Data_Retorno_Ferias__c // "NOT_FOUND"')
VENDER_ABONO=$(cat /tmp/test-c1-case.json | jq -r '.result.records[0].Vender_Abono__c // "NOT_FOUND"')

echo ""
echo "Case Results:"
echo "  - Case Number: $CASE_NUMBER"
echo "  - Case ID: $CASE_ID"
echo "  - Data Inicio: $DATA_INICIO"
echo "  - Data Retorno: $DATA_RETORNO"
echo "  - Vender Abono: $VENDER_ABONO"
echo ""

# Validation
if [ "$DATA_INICIO" == "2026-06-15" ] && [ "$DATA_RETORNO" == "2026-06-22" ] && [ "$VENDER_ABONO" == "false" ]; then
    echo "✅ Case created with CORRECT dates and abono settings"
else
    echo "❌ Case created with INCORRECT data:"
    echo "   Expected: Data_Inicio=2026-06-15, Data_Retorno=2026-06-22, Vender_Abono=false"
    echo "   Got: Data_Inicio=$DATA_INICIO, Data_Retorno=$DATA_RETORNO, Vender_Abono=$VENDER_ABONO"
fi

echo ""
echo "-------------------------------------------"

# 2. Check approval process
if [ "$CASE_ID" != "NOT_FOUND" ]; then
    echo "2. Checking approval process submission..."
    sf data query --query "SELECT Id, Status, TargetObjectId, SubmittedById, CreatedDate FROM ProcessInstance WHERE TargetObjectId = '$CASE_ID' ORDER BY CreatedDate DESC LIMIT 1" --json > /tmp/test-c1-approval.json
    
    APPROVAL_STATUS=$(cat /tmp/test-c1-approval.json | jq -r '.result.records[0].Status // "NOT_FOUND"')
    APPROVAL_ID=$(cat /tmp/test-c1-approval.json | jq -r '.result.records[0].Id // "NOT_FOUND"')
    
    echo ""
    echo "Approval Results:"
    echo "  - Approval ID: $APPROVAL_ID"
    echo "  - Status: $APPROVAL_STATUS"
    echo ""
    
    if [ "$APPROVAL_STATUS" == "Pending" ]; then
        echo "✅ Approval process submitted successfully"
    else
        echo "❌ Approval NOT in Pending status (Status: $APPROVAL_STATUS)"
    fi
else
    echo "⚠️  Skipping approval check - no Case found"
fi

echo ""
echo "-------------------------------------------"

# 3. Display full Case record
echo "3. Full Case Record:"
cat /tmp/test-c1-case.json | jq '.result.records[0]'

echo ""
echo "==========================================="
echo "Verification Complete"
echo "==========================================="
echo ""
echo "Manual Checks Required:"
echo "  - [ ] Agent response text shows 2026 (not 2024)"
echo "  - [ ] Agent response contains CaseNumber: $CASE_NUMBER"
echo "  - [ ] DevTools Network shows 'agendar_ferias' action called"
echo "  - [ ] No errors in browser console or Apex logs"
echo ""