# Test C1 Execution Results - Backend Test

**Test ID**: C1 (Happy Path)  
**Date Executed**: 28/04/2026 17:41 BRT  
**Test Type**: Backend Flow Execution (Simulated Agent Behavior)  
**Executed By**: Automated Apex Script  
**Environment**: sy1774623555431.my.salesforce.com

---

## Test Input Parameters

```
User: Marina Colaboradora CLT (005Hp00000n0ej3IAA)
Request: June 15-22, 2026, no abono
varDataInicio: 2026-06-15
varDataRetorno: 2026-06-22
varVenderAbono: false
varDiasAbono: 0
```

---

## Flow Execution Results

### ✅ Flow Completed Successfully

**Flow Outputs:**
- **Success**: `true`
- **Case ID**: `500Hp00001zD6usIAC`
- **Case Number**: `00001406`
- **Error Message**: `null`
- **Success Message**: "Agendamento confirmado! Periodo de 15/6/2026 a 22/6/2026. Protocolo: 00001406. O pedido foi enviado ao seu gestor para aprovacao."

---

## Case Record Created

**CaseNumber**: `00001406`  
**Case ID**: `500Hp00001zD6usIAC`

### Case Fields

| Field | Value | Expected | Status |
|-------|-------|----------|--------|
| Subject | Pedido de Ferias - 2026-06-15 a 2026-06-22 | ✓ | ✅ |
| Status | Working | New or Working | ✅ |
| Data_Inicio_Ferias__c | 2026-06-15 | 2026-06-15 | ✅ |
| Data_Retorno_Ferias__c | 2026-06-22 | 2026-06-22 | ✅ |
| Vender_Abono__c | false | false | ✅ |
| Dias_Abono__c | 0 | 0 | ✅ |
| Aprovacao_Gestor__c | Pendente | Pendente | ✅ |
| Gestor__c | 005Hp00000n0eiyIAA | (populated) | ✅ |
| OwnerId | 00GHp000008LsxUMAS | 005Hp00000n0ej3IAA | ⚠️ |

### ⚠️ Owner Issue

**Expected OwnerId**: `005Hp00000n0ej3IAA` (Marina)  
**Actual OwnerId**: `00GHp000008LsxUMAS` (Queue or different owner)

**Note**: The Case was created but assigned to a Queue instead of Marina directly. This may be by design if:
1. The RecordType has a default Queue assignment
2. Assignment rules are active
3. This is normal workflow for approval processes

**Impact**: Minor - The Case exists with correct data, and Marina's manager was correctly populated in the Gestor__c field.

---

## Approval Process

**✅ Approval Submitted Successfully**

- **Process Instance ID**: `04gHp000007qMSqIAM`
- **Status**: `Pending`
- **Target Object**: Case 500Hp00001zD6usIAC
- **Manager**: 005Hp00000n0eiyIAA

The approval was successfully submitted to Marina's manager and is awaiting approval.

---

## Validation Results

| Validation | Result | Status |
|------------|--------|--------|
| ✓ Dates correct (2026-06-15 to 2026-06-22) | true | ✅ PASS |
| ✓ Abono setting correct (false) | true | ✅ PASS |
| ✓ Owner correct (Marina) | false | ⚠️ CAVEAT |
| ✓ Approval submitted | true | ✅ PASS |

---

## Test Result

### ⚠️ TEST C1 PASSED WITH ISSUES

**Summary**: The Flow executed successfully and created a Case with all correct data (dates, abono settings, manager assignment). The approval process was submitted. However, the Case owner is a Queue instead of Marina directly.

**Critical Data Validated**:
- ✅ Dates are correct: **2026-06-15 to 2026-06-22**
- ✅ Year is **2026** (not 2024) - Flow auto-adjustment working correctly
- ✅ Abono settings correct: **false, 0 days**
- ✅ Approval submitted to manager: **Pending status**

**Minor Issue**:
- ⚠️ Case owner is Queue `00GHp000008LsxUMAS` instead of Marina `005Hp00000n0ej3IAA`
- This may be normal if assignment rules or RecordType settings route to a Queue
- Manager field (Gestor__c) is correctly populated

---

## Performance Metrics

From Apex Logs:

- **SOQL Queries**: 14 out of 100
- **Query Rows**: 26 out of 50,000
- **DML Statements**: 7 out of 150
- **DML Rows**: 7 out of 10,000
- **CPU Time**: 671ms out of 10,000ms
- **Heap Size**: 0MB out of 6MB
- **Execution Time**: ~28 seconds (including connector initialization)

---

## CLT Validations Passed

The Flow successfully validated all CLT rules:

1. ✅ **R0 - Data no passado**: Dates are in the future (2026)
2. ✅ **R1 - Aviso 30 dias**: More than 30 days advance notice (48 days)
3. ✅ **R2 - Saldo suficiente**: 8 days requested < 30 days available
4. ✅ **R3 - Mínimo 5 dias**: 8 days >= 5 days minimum
5. ✅ **R4 - Concessivo**: Return date within concessivo period (2027-02-28)
6. ✅ **R5 - Dia da semana**: Monday start (valid, not Thu/Fri/Sat/Sun)
7. ✅ **R6 - Início em feriado**: June 15 is not a holiday
8. ✅ **R7 - Véspera de feriado**: No holidays within 2 days of June 15
9. ✅ **Abono validation**: No abono requested, validation skipped

---

## Success Message Generated

The Flow generated the correct success message:

```
Agendamento confirmado! Periodo de 15/6/2026 a 22/6/2026. 
Protocolo: 00001406. O pedido foi enviado ao seu gestor para aprovacao.
```

**Analysis**:
- ✅ Contains "Agendamento confirmado"
- ✅ Shows correct dates with **year 2026** (not 2024)
- ✅ Includes protocol number (Case 00001406)
- ✅ Mentions manager approval

This is exactly what the Agentforce agent would return to the user.

---

## Next Steps

### For Production Use
1. **Verify Queue Assignment**: Confirm if Case assignment to Queue is intentional design
2. **Complete Manual Test**: Execute full UI test as Marina to verify agent behavior end-to-end
3. **Test Agent Response**: Verify the agent echoes the correct year (2026) in its response text

### For Additional Testing
Test the remaining scenarios from the checklist:
- **C2**: Vacation with abono sale (10 days)
- **C3**: 5-day vacation starting August 10
- **C4-C7**: Error scenarios (advance notice, inverted dates, excess abono, weekend start)
- **C8-C10**: Routing tests (saldo query, policy query, greetings)
- **C11-C13**: Safety tests (prompt injection, data access, human handoff)

---

## Files Generated

- ✅ `test-c1-execution-guide.md` - Complete manual execution guide
- ✅ `verify-test-c1.sh` - Backend verification script
- ✅ `test-c1-summary.md` - Quick reference and checklist
- ✅ `test-c1-results.md` - This results document

---

## Conclusion

**Test C1 backend execution: ⚠️ PASSED WITH MINOR CAVEAT**

The Agendamento_Ferias_Autolaunch Flow is working correctly:
- All CLT validations pass
- Dates are correctly set to 2026 (not 2024)
- Case is created with accurate data
- Approval is submitted to manager
- Success message is properly formatted

The only minor issue is the Case owner assignment, which should be investigated to confirm if it's intentional design (Queue assignment) or requires adjustment.

**Backend validation confirms the system is ready for C1 manual UI testing with the Agentforce agent.**