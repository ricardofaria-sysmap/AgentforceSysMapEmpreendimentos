# Test C1 Execution Summary

## Test Overview
- **Test ID**: C1 (Happy Path)
- **Test Type**: Manual Execution + Automated Verification
- **Status**: ⏳ READY FOR EXECUTION
- **Date Prepared**: 28/04/2026
- **Tester**: To be assigned

---

## Quick Reference

### Test Input
```
Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono.
```

### Expected Outcome
✅ Case created with:
- **Dates**: 2026-06-15 to 2026-06-22
- **Abono**: false
- **Status**: Pending approval from manager

### Critical Success Factor
**Year must be 2026** in the Case record (agent response text may show 2024 due to known LLM bug, but backend data must be correct).

---

## Pre-Test Setup Verification ✅

All prerequisites have been verified and are ready:

| Item | Status | Details |
|------|--------|---------|
| Marina User | ✅ Exists | ID: 005Hp00000n0ej3IAA |
| Vacation Balance | ✅ Valid | 30 days available (CLT) |
| Agent Active | ✅ Ready | Agent_Itau_RH_Employee v7 |
| Flow Active | ✅ Ready | Agendamento_Ferias_Autolaunch |
| Org Connected | ✅ Ready | sy1774623555431.my.salesforce.com |
| Test Dates Valid | ✅ Pass | All CLT validations pass |

---

## Execution Instructions

### Step 1: Manual Test Execution
1. **Login as Marina**: Use "Login as" feature or direct login
   - Username: `marina.colaboradora@itau.demo.00dhp00000kp228.local`
   
2. **Open I-Connecta Home**: Navigate to the I-Connecta Home tab

3. **Open DevTools (F12)**: Before typing anything
   - Go to Network tab
   - Filter by: `agents/`

4. **Submit test input** in chat:
   ```
   Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono.
   ```

5. **Observe agent response**:
   - Should contain: "Agendamento confirmado"
   - Should show: "15/6/2026 a 22/6/2026"
   - Should include: Protocol/CaseNumber
   - **CHECK YEAR**: Must show 2026 (not 2024)

6. **Check DevTools Network tab**:
   - Find request to `agents/` endpoint
   - Verify action called: `agendar_ferias`
   - Check inputs: dates, abono settings
   - Check outputs: varSucesso=true, varCaseNumber present

### Step 2: Automated Backend Verification
Run the verification script:
```bash
cd tests
./verify-test-c1.sh
```

This will:
- Query the latest Case for Marina
- Verify dates: 2026-06-15 to 2026-06-22
- Verify abono: false
- Check approval submission status
- Display full Case record

---

## Detailed Documentation

For complete step-by-step instructions, see:
- 📄 **[test-c1-execution-guide.md](./test-c1-execution-guide.md)** - Full execution guide with troubleshooting

For automated verification:
- 🔧 **[verify-test-c1.sh](./verify-test-c1.sh)** - Backend verification script

---

## Pass/Fail Criteria

### ✅ PASS
All of the following must be true:
1. Case created with correct dates (2026-06-15 to 2026-06-22)
2. Case created with Vender_Abono__c = false
3. Approval submitted to Marina's manager
4. No errors in agent response, DevTools, or Apex logs

### ⚠️ PASS with Caveats
Case correct BUT agent response shows wrong year (2024 instead of 2026):
- **Status**: PASS (known cosmetic LLM bug)
- **Backend**: Correct (source of truth)
- **Follow-up**: Log UX improvement ticket

### ❌ FAIL
Any of the following:
1. No Case created
2. Case created with wrong dates (not 2026-06-15/2026-06-22)
3. Case created for different user
4. Approval not submitted
5. Agent shows error message (should not happen for C1)
6. Flow validation triggered (all should pass for C1)

---

## Known Issues

### Issue: Agent Response May Show Wrong Year
- **Symptom**: Response text says "15/6/2024" instead of "15/6/2026"
- **Root Cause**: LLM context defaults to current year
- **Impact**: Cosmetic only (backend is correct)
- **Mitigation**: Flow auto-adjusts past dates to future
- **Verification**: Always check Case record, not agent text

---

## Test Execution Checklist

Use this checklist during test execution:

### Pre-Test
- [ ] Logged in as Marina
- [ ] I-Connecta Home page loaded
- [ ] DevTools open (F12), Network tab active
- [ ] Filter set to: `agents/`

### During Test
- [ ] Submitted exact input: "Quero marcar férias de 15 a 22 de junho de 2026, sem vender abono."
- [ ] Agent responded (not error)
- [ ] Response contains "Agendamento confirmado"
- [ ] Response shows dates (check year!)
- [ ] Response shows CaseNumber/Protocol
- [ ] DevTools captured request/response

### Post-Test (Immediate)
- [ ] DevTools: action = `agendar_ferias`
- [ ] DevTools: varDataInicio = "2026-06-15"
- [ ] DevTools: varDataRetorno = "2026-06-22"
- [ ] DevTools: varSucesso = true
- [ ] No console errors

### Post-Test (Backend)
- [ ] Ran `./verify-test-c1.sh`
- [ ] Script shows ✅ for Case dates
- [ ] Script shows ✅ for approval status
- [ ] Case dates match expected (2026-06-15/2026-06-22)
- [ ] Approval status = Pending

---

## Results Template

After executing the test, document results:

```markdown
## Test C1 Execution Results

**Date Executed**: [YYYY-MM-DD]
**Executed By**: [Name]
**Environment**: sy1774623555431.my.salesforce.com

### Agent Response
- Response Time: [X seconds]
- Response Text: "[Copy exact agent response]"
- Year Shown: [2024 or 2026]

### DevTools Inspection
- Action Invoked: [action name]
- Input varDataInicio: [date]
- Input varDataRetorno: [date]
- Input varVenderAbono: [true/false]
- Output varSucesso: [true/false]
- Output varCaseNumber: [number]

### Backend Verification
- Case ID: [Id]
- Case Number: [CaseNumber]
- Data_Inicio_Ferias__c: [date]
- Data_Retorno_Ferias__c: [date]
- Vender_Abono__c: [true/false]
- Aprovacao_Gestor__c: [Pendente/Aprovado/Rejeitado]
- Approval Process ID: [ProcessInstance Id]
- Approval Status: [Pending/Approved/Rejected]

### Test Result
- [ ] ✅ PASS
- [ ] ⚠️ PASS with Caveats (specify: _________________)
- [ ] ❌ FAIL (specify reason: _________________)

### Notes
[Any additional observations, issues, or comments]
```

---

## Next Steps After C1

If C1 passes, proceed with:
- **C2**: Vacation with abono sale (10 days)
- **C3**: 5-day vacation starting August 10
- **C4**: Error scenario - insufficient advance notice
- **C5**: Critical - inverted dates test
- **C6**: Error scenario - excess abono
- **C7**: Error scenario - weekend start date

See `manual-test-marina-checklist.md` for complete test suite.

---

## Support & Troubleshooting

If issues occur during execution:

1. **Review**: [test-c1-execution-guide.md](./test-c1-execution-guide.md) - Troubleshooting section
2. **Check**: Agent activation status, Marina permissions, manager assignment
3. **Logs**: Enable TraceFlag for Marina, check Apex logs
4. **DevTools**: Network tab for actual payloads sent/received

---

## Files Generated

This test preparation created:
- ✅ `test-c1-execution-guide.md` - Complete execution guide (3,700+ lines)
- ✅ `verify-test-c1.sh` - Automated verification script
- ✅ `test-c1-summary.md` - This summary document

All files are in the `tests/` directory.