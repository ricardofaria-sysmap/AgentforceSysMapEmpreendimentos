# Test C1 - Issue Analysis: Agent Escalating Instead of Scheduling

**Date**: 28/04/2026  
**Test**: C1 - Happy Path Vacation Request  
**Issue**: Agent incorrectly escalates to human instead of executing vacation scheduling

---

## Observed Behavior

### User Input (Marina)
```
Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono.
```

### Expected Agent Response
```
Agendamento confirmado! Periodo de 15/6/2026 a 22/6/2026. 
Protocolo: 00001406. O pedido foi enviado ao seu gestor para aprovacao.
```

### Actual Agent Response ❌
```
Um atendente humano de RH vai assumir seu atendimento em breve. 
Você estava tentando agendar férias de 15 a 22 de junho, sem vender abono.
```

**Result**: Agent routed to `escalation` topic instead of completing the scheduling.

---

## Backend Validation ✅

The Flow `Agendamento_Ferias_Autolaunch` was tested directly and **WORKS PERFECTLY**:
- ✅ Case created: #00001406
- ✅ Dates correct: 2026-06-15 to 2026-06-22
- ✅ All CLT validations passed
- ✅ Approval submitted: Pending
- ✅ Success message generated correctly

**Conclusion**: The backend is working. The issue is in the Agent Script reasoning/execution.

---

## Root Cause Analysis

### Agent Script Flow (Expected)

According to `Agent_Itau_RH_Employee.agent`:

```
topic_selector → agendamento_ferias
  ↓
1. Call pesquisar_saldo (REGRA ABSOLUTA 1)
  ↓
2. Check if success=true and user wants to schedule (Caso C)
  ↓
3. Extract dates from user input
  ↓
4. Set DataInicio and DataRetorno variables
  ↓
5. Confirm abono preference (already provided: false)
  ↓
6. Call executar_agendamento
  ↓
7. If varSucesso=true, return success message with CaseNumber
```

### What Likely Happened

The agent followed this path instead:

```
topic_selector → agendamento_ferias
  ↓
1. Call pesquisar_saldo ✅ (returned 30 days available)
  ↓
2. Identified user wants to schedule (Caso C) ✅
  ↓
3. ❌ FAILED to extract dates or set variables correctly
  ↓
4. ❌ Instead of calling executar_agendamento, called escalar
  ↓
5. Routed to escalation topic
```

---

## Possible Causes

### 1. Date Extraction Failure

**Hypothesis**: The LLM is struggling to extract and convert dates from natural language Portuguese.

**Evidence**:
- User said: "15 a 22 de junho de 2026"
- Agent needs to convert to: DataInicio="2026-06-15", DataRetorno="2026-06-22"
- This requires understanding Portuguese date format and ISO conversion

**Agent Script section**:
```
Caso C - usuario quer AGENDAR:
1. Reporte o saldo em 1 frase e peca as datas de inicio e retorno no formato DD/MM/AAAA se ainda nao informadas.
   Converta para ISO YYYY-MM-DD e salve via capturar_datas.
```

**Problem**: The instruction says "se ainda não informadas" (if not yet provided), but the dates WERE provided. The agent may be confused about whether to:
- Extract the provided dates directly
- Ask for confirmation first
- Fail and escalate

### 2. Missing Intermediate Steps

The Agent Script expects this multi-turn flow:
1. Ask for dates (if not provided)
2. Ask about abono
3. Confirm all data
4. Execute

But the user provided **everything in one message**:
- ✅ Dates: "15 a 22 de junho de 2026"
- ✅ Abono: "sem vender abono"

The agent may not be handling the "all-in-one" input correctly.

### 3. Variable Setting Issues

The agent needs to call:
```
capturar_datas: @utils.setVariables
    with DataInicio = ...
    with DataRetorno = ...

capturar_abono: @utils.setVariables
    with VenderAbono = ...
    with DiasAbono = ...
```

If these actions fail or are skipped, `executar_agendamento` won't have the required inputs, causing escalation.

### 4. LLM Reasoning Error

The model may be:
- Over-cautious and escalating when uncertain
- Not confident in date parsing
- Misinterpreting the reasoning instructions

---

## Evidence Needed

To confirm the root cause, we need to check:

1. **Agent Session Logs** (if available):
   - Which actions were actually called?
   - Were variables set correctly?
   - What was the reasoning output?

2. **Network DevTools Payload**:
   - What did the agent send to `agendar_ferias` action?
   - Were DataInicio/DataRetorno populated?
   - Or was `executar_agendamento` never called?

3. **Trace/Debug Output**:
   - Check Salesforce Setup → Einstein Copilot → Debug Console
   - Look for conversation flow and action invocations

---

## Recommended Fixes

### Fix Option 1: Improve Date Extraction Instructions

**Current instruction** (vague):
```
"Converta para ISO YYYY-MM-DD e salve via capturar_datas."
```

**Improved instruction**:
```
"Quando o colaborador informar datas (ex: '15 a 22 de junho de 2026', '10/06 a 20/06', 'de 5 até 15 de agosto'):
1. Extraia a data de INÍCIO (primeiro dia mencionado)
2. Extraia a data de RETORNO (último dia mencionado)  
3. Se o ano não for mencionado, assuma o ano corrente (2026)
4. Converta ambas para formato ISO YYYY-MM-DD:
   - '15 de junho de 2026' → '2026-06-15'
   - '22 de junho' → '2026-06-22'
5. Chame capturar_datas imediatamente com esses valores
6. Não peça confirmação das datas - prossiga para abono"
```

### Fix Option 2: Handle All-In-One Input

Add explicit handling for when all information is provided at once:

```
"Se o colaborador fornecer TUDO de uma vez (datas + abono):
1. Extraia as datas e salve via capturar_datas
2. Extraia a decisão de abono:
   - 'sem vender abono' → VenderAbono=false, DiasAbono=0
   - 'vendendo X dias' → VenderAbono=true, DiasAbono=X
3. Salve via capturar_abono
4. PULE a fase de perguntas - vá direto para executar_agendamento
5. Confirme apenas APÓS o sucesso do agendamento"
```

### Fix Option 3: Add Fallback Before Escalation

```
"ANTES de chamar escalar, verifique:
1. Você já tentou extrair as datas? Se não, tente agora.
2. Você chamou pesquisar_saldo? Se sim e success=true, continue.
3. As variáveis DataInicio e DataRetorno estão vazias? Se sim, PERGUNTE as datas.
4. APENAS escale se:
   - TentativasAgendamento >= 3
   - OU o colaborador pedir explicitamente por humano
   - OU pesquisar_saldo retornou success=false"
```

### Fix Option 4: Simplify Caso C Instructions

**Problem**: The instructions are too complex with multiple sub-steps.

**Solution**: Break into clear, sequential mini-tasks:

```
Caso C - Agendamento com datas fornecidas:

PASSO 1 - Extração:
Se o colaborador já forneceu datas no input, extraia-as AGORA e salve via capturar_datas.
Se não forneceu, pergunte: "Para qual período você quer agendar? Informe as datas de início e retorno (ex: 15/06 a 22/06)."

PASSO 2 - Abono:
Se o colaborador já mencionou abono ("sem vender", "vendendo X dias"), salve via capturar_abono.
Se não mencionou, pergunte: "Deseja vender abono pecuniário (até 10 dias)?"

PASSO 3 - Execução:
Se DataInicio E DataRetorno E VenderAbono estão definidos, chame executar_agendamento AGORA.

PASSO 4 - Resultado:
Se varSucesso=true: informe "Agendamento confirmado! Período de [DataInicio] a [DataRetorno]. Protocolo: [varCaseNumber]."
Se varSucesso=false: explique varMensagemErro e incremente TentativasAgendamento.
```

---

## Testing Strategy

### Immediate Test
1. Add more explicit instructions to Caso C
2. Redeploy agent
3. Test again with exact same input: "Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono."
4. Check if agent now completes scheduling

### Alternative Inputs to Test
- "Marcar férias 15/06/2026 a 22/06/2026 sem abono" (explicit format)
- "Quero tirar férias em junho, de 15 a 22, sem vender abono" (variation)
- Two-step: "Quero marcar férias" → (agent asks) → "15 a 22 de junho"

---

## Next Steps

1. **Capture Agent Session Log**: Get the actual conversation trace from Einstein Copilot debug console
2. **Apply Fix Option 2 or 4**: Update Agent Script with clearer instructions for all-in-one input
3. **Test with Simple Input**: Try "Quero agendar férias de 15/06/2026 a 22/06/2026" (numeric dates)
4. **Add Debug Output**: Temporarily add debug messages in Agent Script to see variable states
5. **Consider Model Upgrade**: If LLM reasoning is the issue, test with a more capable model

---

## Expected Outcome After Fix

**User Input**:
```
Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono.
```

**Agent Flow** (corrected):
```
1. pesquisar_saldo → success=true, diasDisponiveis=30 ✅
2. Identify Caso C (agendar com datas fornecidas) ✅
3. Extract dates: "15 de junho de 2026" → "2026-06-15" ✅
                   "22 de junho de 2026" → "2026-06-22" ✅
4. capturar_datas(DataInicio="2026-06-15", DataRetorno="2026-06-22") ✅
5. Extract abono: "sem vender abono" → VenderAbono=false, DiasAbono=0 ✅
6. capturar_abono(VenderAbono=false, DiasAbono=0) ✅
7. executar_agendamento(...) → varSucesso=true, varCaseNumber="00001406" ✅
8. Response: "Agendamento confirmado! Período de 15/6/2026 a 22/6/2026. Protocolo: 00001406. O pedido foi enviado ao seu gestor para aprovação." ✅
```

**Status**: ✅ TEST C1 PASS

---

## Priority

**HIGH** - This is a critical failure of the primary use case. The agent must be able to schedule vacations when all information is provided clearly.

**Impact**: Blocks all vacation scheduling via agent. Users must escalate to human for basic requests.

**Urgency**: Fix before production deployment.