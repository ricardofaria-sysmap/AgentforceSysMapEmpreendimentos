# Deploy na Org do Brasal — `AgentforceSysmapEmpreendimentos`

Guia específico para subir a demo RH do Itaú na mesma Salesforce Demo Org (SDO) que hospeda o agente do Brasal, em vez de provisionar uma org Developer nova.

## Por que reusar a org

Identificada pela configuração em `Repos/AgentforceBrasal/AgentforceSysmapEmpreendimentos/.sf/config.json` (alias `AgentforceSysmapEmpreendimentos`). Já vem com:

- Agentforce / Einstein habilitados (bot `Agent_Brasal_Teste` funcionando)
- Knowledge ligado (`Knowledge__kav` presente)
- Messaging Channels + `EmbeddedServiceConfig` (templates prontos do Brasal)
- Service Cloud completo
- API source 66.0

Vantagens práticas:

1. Zero provisionamento / licenças já alocadas
2. Pipeline Agentforce pronto (economiza 2-3h de setup)
3. Possibilita mostrar dois casos de uso na mesma demo: B2C leads (Brasal) + Employee Agent (Itaú)

## Análise de conflitos

Verificado: **nenhum conflito real**. Todos os nomes do Itaú são prefixados ou semanticamente distintos.

| Componente Itaú | Presente no Brasal? | Status |
|---|---|---|
| `Saldo_Ferias__c` (custom object) | não | aditivo |
| Custom fields no `Case` | não | aditivo |
| RecordType `Case.Pedido_Ferias` | Case sem RTs Brasal | aditivo |
| `Agentforce_RH_Colaborador` permset | não | aditivo |
| `Agentforce_RH_Gestor` permset | não | aditivo |
| Email folder `Itau_RH` + templates | não | aditivo |
| Agent `Itau_RH_Agent` | coexiste com `Agent_Brasal_Teste` | novo agente |
| Topic `Consulta_Politicas_RH` | escopos distintos | aditivo |
| Users `*.itau.demo.local` | domínio isolado | sem colisão |

## Checklist pré-deploy

- [ ] `sourceApiVersion` no `sfdx-project.json` = `66.0` (igual à org)
- [ ] Autenticado com `sf org login web -a AgentforceSysmapEmpreendimentos`
- [ ] Verificar licenças Standard User disponíveis (SDO costuma ter poucas sobras) — se apertado, criar só Marina e Carlos, deixar Pedro opcional
- [ ] Confirmar que Knowledge tem Data Category Group com capacidade para adicionar `RH > Ferias`, `RH > Beneficios`, `RH > Home_Office` OU criar grupo novo `RH` (respeita limite de 5 grupos ativos)
- [ ] Confirmar que Case não tem trigger/flow global que bloqueie a criação via Screen Flow do Agentforce

## Ordem de deploy

### 1. Dry-run primeiro

```bash
./scripts/deploy.sh AgentforceSysmapEmpreendimentos --dry-run
```

Esperar zero erros antes de persistir. Se falhar em validação, ajustar e repetir.

### 2. Deploy por camadas

```bash
./scripts/deploy.sh AgentforceSysmapEmpreendimentos
```

O script já desempacota em 4 etapas (objects → permsets → email → flows/bots) para facilitar debug se algo quebrar.

### 3. Users e dados

```bash
./scripts/create-users.sh AgentforceSysmapEmpreendimentos
./scripts/bootstrap-data.sh AgentforceSysmapEmpreendimentos
```

### 4. Componentes via UI da org

Criar manualmente nesta ordem:

1. **Approval Process** `Aprovacao_Pedido_Ferias` em Case (entry criteria: RecordType = Pedido_Ferias AND Status = Pendente Aprovacao)
2. **Knowledge Record Type** `Politica_RH`
3. **Data Categories**: `RH > Ferias`, `RH > Beneficios`, `RH > Home_Office`
4. **5 Knowledge Articles** (conteúdo em `docs/knowledge-articles/*.md`)
5. **Screen Flow** `Agendamento_Ferias_Screen` (spec em [`SCREEN_FLOW.md`](SCREEN_FLOW.md))
6. **Record-Triggered Flow** `Case_Ferias_Aprovado_Pos` com Scheduled Path 5d
7. **Agent** `Itau_RH_Agent` (não modificar o `Agent_Brasal_Teste`)
8. **Topic** `Consulta_Politicas_RH` (spec em [`TOPIC_AGENTE_A.md`](TOPIC_AGENTE_A.md))
9. **Custom Actions** no Topic: `Agendar_Ferias`, `Criar_Caso_Duvida_RH`, `Consultar_Saldo_Ferias`
10. **Messaging Channel** `Itau_Employee_Chat` (copiar como base o `Agentforce_Brasal_Github_Page`)
11. **EmbeddedServiceConfig** `Itau_RH_Portal` (branding Itaú, apontando só para `Itau_RH_Agent`)

### 5. Retrieve e versionamento

```bash
./scripts/retrieve.sh AgentforceSysmapEmpreendimentos
git add -A && git commit -m "feat: componentes Agentforce puxados da org"
```

## Separação de escopos no Agent

**Crítico:** não adicionar o Topic RH ao `Agent_Brasal_Teste`. Cada caso de uso tem seu próprio agente:

- `Agent_Brasal_Teste` → EmbeddedServiceConfig `Agentforce_Brasal_Github_Page` → público externo (SDR / leads)
- `Itau_RH_Agent` → EmbeddedServiceConfig `Itau_RH_Portal` → colaborador interno

Dessa forma, na página de demo do Brasal só aparece o agente do Brasal. Na página do Itaú, só aparece o agente do Itaú. A org é a mesma, mas as experiências são isoladas.

## Rollback

Se algo der errado e for preciso remover a demo da org:

```bash
sf project delete source \
  -o AgentforceSysmapEmpreendimentos \
  -m "CustomObject:Saldo_Ferias__c" \
  -m "CustomField:Case.Data_Inicio_Ferias__c" \
  -m "CustomField:Case.Data_Retorno_Ferias__c" \
  -m "CustomField:Case.Quantidade_Dias__c" \
  -m "CustomField:Case.Vender_Abono__c" \
  -m "CustomField:Case.Dias_Abono__c" \
  -m "CustomField:Case.Saldo_Ferias_Ref__c" \
  -m "CustomField:Case.Gestor__c" \
  -m "CustomField:Case.Aprovacao_Gestor__c" \
  -m "CustomField:Case.Data_Notificacao_Lembrete__c" \
  -m "RecordType:Case.Pedido_Ferias" \
  -m "PermissionSet:Agentforce_RH_Colaborador" \
  -m "PermissionSet:Agentforce_RH_Gestor" \
  -m "EmailFolder:Itau_RH"
```

Users e Saldo_Ferias__c records ficam — removê-los manualmente se necessário (soft via `Status__c = Concluido` ou hard via `sf data delete record`).

## Pontos de atenção durante a demo

- Se abrir o chat do Brasal e do Itaú em abas diferentes, confirmar que cada um responde com o agente correto
- Knowledge search pode retornar artigos dos dois domínios se não houver filtro por Record Type — os 5 artigos RH devem ter `RT = Politica_RH` e Data Category específica
- Ao demonstrar Flow de agendamento, garantir que o `varFeriados` (lista de feriados 2026) esteja atualizado considerando a data da demo
