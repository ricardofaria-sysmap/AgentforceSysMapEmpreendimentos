# Test C1 Execution Guide - Marina Vacation Request
**Test Case**: C1 - Happy Path (Caminho feliz)
**Date**: 28/04/2026
**Tester**: Test Execution via Manual Process

## Test Scenario
Request vacation from June 15-22, 2026, without selling vacation bonus (abono).

## Pre-Test Verification ✅

### 1. Marina User Confirmed
- **User ID**: `005Hp00000n0ej3IAA`
- **Username**: `marina.colaboradora@itau.demo.00dhp00000kp228.local`
- **Name**: Marina Colaboradora CLT
- **Email**: marina.colaboradora@itau.demo.00dhp00000kp228.local

### 2. Vacation Balance Confirmed
- **Saldo ID**: `a2wHp00000735CEIAY`
- **Available Days**: 30 days
- **Total Days**: 30 days
- **Regime**: CLT
- **Status**: Vigente (Valid)
- **Concessivo End**: 2027-02-28

### 3. Agent Configuration Confirmed
- **Agent Name**: Agent_Itau_RH_Employee
- **Active Version**: v7
- **Planner**: Agent_Itau_RH_Employee_v7
- **Type**: AgentforceEmployeeAgent (runs in user context)
- **Flow**: Agendamento_Ferias_Autolaunch (Active)

### 4. Date Validation for Request
Request dates: **June 15-22, 2026** (8 days total)
- Start: 2026-06-15 (Monday) ✅
- End: 2026-06-22 (Monday return)
- Days requested: 8 calendar days
- Within 30-day advance notice: ✅ (request is from today 2026-04-28, 48 days in advance)
- Not starting Thu/Fri/Sat/Sun: ✅ (Monday is valid)
- Minimum 5 days: ✅ (8 days > 5)
- Within concessivo period: ✅ (ends 2027-02-28)
- Sufficient balance: ✅ (8 days < 30 available)

**Expected Result**: ✅ ALL VALIDATIONS PASS - Case should be created successfully

---

## Test Execution Steps

### Step 1: Login as Marina
```bash
# Option A: Using Salesforce CLI (for backend testing)
sf org login web --alias marina-test --instance-url https://sy1774623555431.my.salesforce.com

# Option B: Via Browser (for UI testing)
# 1. Go to Setup → Users
# 2. Find Marina Colaboradora CLT
# 3. Click "Login" button
# 4. Navigate to I-Connecta Home
```

### Step 2: Open Agentforce Chat
**Via I-Connecta Home** (preferred):
1. Navigate to the I-Connecta Home tab
2. Locate the embedded Agentforce chat component
3. Chat should auto-load with welcome message

**Via Setup Preview**:
1. Setup → Agents → Agent Itau RH (Employee)
2. Click "Preview" button
3. Opens in new window

### Step 3: Submit Test Input
**Exact input to type in chat**:
```
Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono.
```

### Step 4: Monitor Agent Response
Expected agent behavior sequence:
1. **Route to `agendamento_ferias` topic** (detects vacation scheduling intent)
2. **Call `consultar_saldo` action** (retrieves Marina's balance)
3. **Present balance**: "Você tem 30 dias disponíveis (regime CLT)..."
4. **Confirm dates**: Agent extracts June 15-22, 2026
5. **Confirm abono**: No abono (varVenderAbono=false, varDiasAbono=0)
6. **Call `agendar_ferias` action** with:
   - varUserId: "" (resolves to Marina's ID via $User.Id)
   - varDataInicio: "2026-06-15"
   - varDataRetorno: "2026-06-22"
   - varVenderAbono: false
   - varDiasAbono: 0
7. **Flow executes** all CLT validations (should pass all)
8. **Case created** with RecordType Pedido_Ferias
9. **Approval submitted** to Marina's manager
10. **Agent responds** with success message

**Expected Response Format**:
```
Agendamento confirmado! Periodo de 15/6/2026 a 22/6/2026. 
Protocolo: <CaseNumber>. O pedido foi enviado ao seu gestor para aprovacao.
```

### Step 5: Open Browser DevTools (F12)
**Critical for debugging**:
1. Open DevTools **before** submitting the message
2. Go to **Network** tab
3. Filter by: `agents/`
4. After agent responds, inspect:
   - Request payload (action called, input parameters)
   - Response payload (topic routed, outputs returned)
   - Look for: `agendar_ferias` action invocation

---

## Verification Checklist

### ✅ Immediate Verification (During Test)

- [ ] **Agent Response Text**
  - Contains "Agendamento confirmado"
  - Shows dates: "15/6/2026 a 22/6/2026"
  - Shows protocol/CaseNumber
  - Mentions "gestor para aprovacao"
  - **CRITICAL**: Year shown is 2026 (NOT 2024)

- [ ] **DevTools Network Payload**
  - Action invoked: `agendar_ferias`
  - Input `varDataInicio`: "2026-06-15"
  - Input `varDataRetorno`: "2026-06-22"
  - Input `varVenderAbono`: false
  - Input `varDiasAbono`: 0
  - Output `varSucesso`: true
  - Output `varCaseNumber`: present
  - Output `varMensagemSucesso`: contains confirmation

### ✅ Backend Verification (After Test)

#### 1. Query Latest Case Created
```bash
sf data query --query "SELECT Id, CaseNumber, Subject, Status, Data_Inicio_Ferias__c, Data_Retorno_Ferias__c, Vender_Abono__c, Dias_Abono__c, Aprovacao_Gestor__c, OwnerId, Gestor__c FROM Case WHERE OwnerId = '005Hp00000n0ej3IAA' ORDER BY CreatedDate DESC LIMIT 1" --json
```

**Expected Case Fields**:
- [ ] `CaseNumber`: present (e.g., "00001234")
- [ ] `Subject`: "Pedido de Ferias - 2026-06-15 a 2026-06-22"
- [ ] `Status`: "New"
- [ ] `Data_Inicio_Ferias__c`: "2026-06-15"
- [ ] `Data_Retorno_Ferias__c`: "2026-06-22"
- [ ] `Vender_Abono__c`: false
- [ ] `Dias_Abono__c`: 0 (or null)
- [ ] `Aprovacao_Gestor__c`: "Pendente"
- [ ] `OwnerId`: "005Hp00000n0ej3IAA" (Marina)
- [ ] `Gestor__c`: Marina's manager ID (should be populated)

#### 2. Query Approval Process Submission
```bash
sf data query --query "SELECT Id, Status, TargetObjectId, ProcessDefinitionId, SubmittedById, CreatedDate FROM ProcessInstance WHERE TargetObjectId IN (SELECT Id FROM Case WHERE OwnerId = '005Hp00000n0ej3IAA' ORDER BY CreatedDate DESC LIMIT 1) ORDER BY CreatedDate DESC LIMIT 1" --json
```

**Expected Approval**:
- [ ] `Status`: "Pending"
- [ ] `TargetObjectId`: matches Case Id
- [ ] `SubmittedById`: "005Hp00000n0ej3IAA" (Marina)

#### 3. Check Apex Logs (if TraceFlag enabled)
```bash
# List logs for Marina
sf apex list log --json | jq '.result[] | select(.LogUserId == "005Hp00000n0ej3IAA")'

# Get specific log
sf apex get log --log-id <LogId>
```

**Look for**:
- ConsultarSaldoFerias invocation
- Agendamento_Ferias_Autolaunch flow execution
- FeriasApprovalSubmitter invocation
- No errors or exceptions

---

## Success Criteria

### ✅ PASS Conditions
1. **Agent response** contains correct protocol number
2. **Agent response** shows dates as **2026** (not 2024)
3. **Case created** with all correct field values
4. **Approval submitted** to manager
5. **No errors** in DevTools console or Apex logs
6. **Flow completed** without exceptions

### ⚠️ PASS with Caveats
1. Case created correctly BUT agent response text shows wrong year (2024 instead of 2026)
   - **Status**: PASS with cosmetic issue
   - **Note**: Known LLM bug - backend data is correct, response text formatting issue
   - **Impact**: Low (backend is source of truth)
   - **Follow-up**: Log as UX improvement ticket

### ❌ FAIL Conditions
1. **No Case created** - agent failed to invoke flow
2. **Case created with wrong dates** - flow or agent date parsing issue
3. **Case created for different user** - security/context issue
4. **Approval not submitted** - FeriasApprovalSubmitter failure
5. **Agent shows error message** - flow validation failed (should pass for this scenario)
6. **DevTools shows action not called** - routing failure

---

## Known Issues / Expected Behavior

### Issue 1: Agent May Echo Wrong Year in Text
**Symptom**: Agent response says "15/6/2024" instead of "15/6/2026"  
**Root Cause**: LLM inference sometimes defaults to current year context  
**Verification**: Check the **actual Case record** - `Data_Inicio_Ferias__c` field  
**Status**: Known cosmetic bug, backend data is always correct  
**Workaround**: Flow has `Formula_DataInicioAjustada` that fixes past dates

### Issue 2: Flow Auto-Adjusts Past Dates
**Behavior**: If agent sends 2024-06-15 (past date), flow automatically moves to 2026-06-15  
**Formulas**:
- `Formula_DataInicioAjustada`: adds years to bring date to future
- `Formula_DataRetornoAjustada`: same for return date  
**Result**: Case always has correct future dates even if agent input was wrong

---

## Troubleshooting

### Problem: Agent doesn't respond
**Causes**:
- Agent not published/active
- Network issue
- Permission issue (Marina missing `Agentforce_RH_Colaborador` permission set)

**Check**:
```bash
# Verify agent is active
sf data query --query "SELECT Id, IsActive, MasterLabel FROM Bot WHERE DeveloperName = 'Agent_Itau_RH_Employee'" --json

# Check Marina's permission sets
sf data query --query "SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = '005Hp00000n0ej3IAA'" --json
```

### Problem: Agent routes to wrong topic
**Symptom**: Agent calls `consultar_politicas` instead of `agendar_ferias`  
**Cause**: Routing logic in `topic_selector` misinterpreted intent  
**Check**: DevTools Network → look for topic in response  
**Status**: If this happens, **FAIL** - routing is broken

### Problem: Flow returns error
**Symptom**: `varSucesso=false`, `varMensagemErro` populated  
**Cause**: CLT validation failed  
**Status**: For C1, this should NOT happen (all validations pass)  
**If it happens**: **FAIL** - investigate which validation triggered

### Problem: No approval submitted
**Symptom**: Case created but no ProcessInstance record  
**Check**:
```bash
# Check if Marina has a manager
sf data query --query "SELECT Id, ManagerId FROM User WHERE Id = '005Hp00000n0ej3IAA'" --json
```
**Cause**: Marina has no manager → flow fails at approval submission  
**Fix**: Assign manager to Marina via Setup → Users

---

## Test Execution Command Line Script

For automated backend verification after manual test execution:

```bash
#!/bin/bash
# save as: tests/verify-test-c1.sh

echo "=== Test C1 Verification Script ==="
echo ""

# Get latest Case for Marina
echo "1. Checking latest Case created for Marina..."
CASE_QUERY="SELECT Id, CaseNumber, Subject, Data_Inicio_Ferias__c, Data_Retorno_Ferias__c, Vender_Abono__c, Aprovacao_Gestor__c FROM