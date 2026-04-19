# force-app — Metadados SFDX

Esta pasta contém o **subset deployável** dos metadados da demo. Componentes Agentforce (Agent, Topic, GenAiPlugin, GenAiFunction) e Screen Flows complexos são mais fáceis de criar via UI na org e depois fazer `sf project retrieve start` para trazer para cá.

## O que está pronto para deploy

### `objects/Saldo_Ferias__c/`
Objeto customizado completo:
- `Colaborador__c` (Lookup User)
- `Regime_Contratacao__c` (Picklist CLT/PJ)
- `Periodo_Aquisitivo_Inicio__c` (Date)
- `Periodo_Aquisitivo_Fim__c` (Formula Date)
- `Periodo_Concessivo_Fim__c` (Formula Date)
- `Faltas_Injustificadas__c` (Number)
- `Dias_Direito__c` (Formula Number — escala art. 130 CLT com switch CLT/PJ)
- `Dias_Tirados__c` (Number)
- `Dias_Abono_Vendidos__c` (Number)
- `Dias_Disponiveis__c` (Formula Number)
- `Status__c` (Picklist)
- Validation Rule `Abono_Maximo_1_3`

### `objects/Case/`
Custom fields + RecordType `Pedido_Ferias`:
- `Data_Inicio_Ferias__c`, `Data_Retorno_Ferias__c`
- `Quantidade_Dias__c` (formula)
- `Vender_Abono__c`, `Dias_Abono__c`
- `Saldo_Ferias_Ref__c` (Lookup → Saldo_Ferias__c)
- `Gestor__c` (Lookup → User)
- `Aprovacao_Gestor__c` (Picklist)
- `Data_Notificacao_Lembrete__c` (formula Date = início - 5)

### `permissionsets/`
- `Agentforce_RH_Colaborador` — para Marina e Pedro
- `Agentforce_RH_Gestor` — para Carlos

### `email/Itau_RH/`
- `EmailTemplate_Ferias_Aprovado`
- `EmailTemplate_Ferias_Lembrete`

## O que deve ser criado na UI e retrieved depois

1. **Approval Process** `Aprovacao_Pedido_Ferias` em Case
2. **Screen Flow** `Agendamento_Ferias_Screen` (ver `docs/SCREEN_FLOW.md`)
3. **Record-Triggered Flow** `Case_Ferias_Aprovado_Pos` com Scheduled Path 5d
4. **Knowledge**: Record Type `Politica_RH`, Data Categories, 5 artigos (conteúdo em `docs/knowledge-articles/`)
5. **Agentforce Agent** `Itau_RH_Agent` + Topic `Consulta_Politicas_RH` + Custom Actions
6. **Messaging Channel** `Itau_Employee_Chat` + **EmbeddedServiceConfig** `Itau_RH_Portal`

Após criar na UI:
```bash
./scripts/retrieve.sh <alias-da-org>
```

## Ordem de deploy recomendada

```bash
# 1. Validar sem persistir
./scripts/deploy.sh <alias> --dry-run

# 2. Deploy real (4 camadas: objects, permsets, email, flows/bots)
./scripts/deploy.sh <alias>
```
