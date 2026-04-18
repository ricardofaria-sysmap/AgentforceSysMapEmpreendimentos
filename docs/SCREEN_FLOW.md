# Screen Flow `Agendamento_Ferias_Screen`

Arquivo: `force-app/main/default/flows/Agendamento_Ferias_Screen.flow-meta.xml`

## Metadados

- API Name: `Agendamento_Ferias_Screen`
- Type: Screen Flow (`processType = Flow`)
- API Version: 66.0
- Run In Mode: `SystemModeWithoutSharing` (para ler `User.ManagerId` mesmo sem sharing explícito)
- Invocável por: Agentforce Custom Action, botão de Quick Action no Home e direto via URL `/flow/Agendamento_Ferias_Screen`

## Variáveis / Recursos

### Input
| Nome | Tipo | Descrição |
|---|---|---|
| `varUserId` | Text | default `{!$User.Id}` |

### Internas
| Nome | Tipo | Descrição |
|---|---|---|
| `varDataInicio` | Date | data de início escolhida |
| `varDataRetorno` | Date | data de retorno escolhida |
| `varVenderAbono` | Boolean | checkbox (default `false`) |
| `varDiasAbono` | Number (scale 0) | dias de abono (default `0`) |
| `varMensagemErro` | Text | mensagem para a Tela_Erro |

### Output
| Nome | Tipo | Descrição |
|---|---|---|
| `varCaseId` | Text | (reservado; hoje o Case criado fica em `{!Criar_Case}`) |

### Formulas
| Nome | Tipo | Expressão |
|---|---|---|
| `fxDiasSolicitados` | Number | `varDataRetorno - varDataInicio + 1` |
| `fxDiasAteInicio` | Number | `varDataInicio - TODAY()` |
| `fxLimiteAbono` | Number | `FLOOR(Get_Saldo_Atual.Dias_Direito__c / 3) - BLANKVALUE(Get_Saldo_Atual.Dias_Abono_Vendidos__c, 0)` |
| `fxDiaSemanaInicio` | Number | `WEEKDAY(varDataInicio)` (1=Dom, 2=Seg, ..., 7=Sáb) |
| `fxVesperaFeriado` | Boolean | `OR(varDataInicio+1 == feriado, varDataInicio+2 == feriado)` para feriados nacionais 2026 hardcoded |
| `fxAssuntoCase` | String | `"Pedido de Ferias - " & TEXT(varDataInicio) & " a " & TEXT(varDataRetorno)` |
| `fxDataLembrete` | Date | `varDataInicio - 5` (não usada hoje; reservada para o scheduled flow) |

### Text Templates
- `textCabecalho`, `textSaldo` — Tela_Boas_Vindas
- `textAbonoInfo` — Tela_Abono
- `textResumo` — Tela_Confirmacao
- `textSucesso` — Tela_Sucesso
- `textErro` — Tela_Erro

## Lookups / DML

| Elemento | Tipo | Objeto | Filtro | Output |
|---|---|---|---|---|
| `Get_Saldo_Atual` | Get Records | `Saldo_Ferias__c` | `Colaborador__c = varUserId` AND `Status__c = 'Vigente'` | `{!Get_Saldo_Atual}` |
| `Get_Manager` | Get Records | `User` | `Id = varUserId` | `{!Get_Manager.ManagerId}` |
| `Get_RT_Pedido_Ferias` | Get Records | `RecordType` | `SobjectType='Case' AND DeveloperName='Pedido_Ferias'` | `{!Get_RT_Pedido_Ferias.Id}` |
| `Criar_Case` | Create Records | `Case` | ver abaixo | `{!Criar_Case}` (Id do Case criado) |

## Fluxo resumido

```
Start
 └── Get_Saldo_Atual
      └── Decision_Saldo_Existe
           ├── Tem_Saldo → Get_Manager → Get_RT_Pedido_Ferias → Tela_Boas_Vindas
           └── Nao encontrou → Tela_Sem_Saldo (END)

Tela_Boas_Vindas → Tela_Selecao_Datas → Set_Datas_Vars → Valida_CLT
     ├── R1 Aviso 30d            → Set_Erro_Aviso_30d      → Tela_Erro
     ├── R2 Saldo insuficiente   → Set_Erro_Saldo          → Tela_Erro
     ├── R3 Mínimo 5 dias        → Set_Erro_Minimo_5       → Tela_Erro
     ├── R4 Fora do concessivo   → Set_Erro_Concessivo     → Tela_Erro
     ├── R5 Sex/Sáb/Dom          → Set_Erro_Dia_Semana     → Tela_Erro
     ├── R6 Véspera de feriado   → Set_Erro_Vespera_Feriado→ Tela_Erro
     └── Default (OK)            → Decision_Abono
                                      ├── fxLimiteAbono > 0 → Tela_Abono → Set_Abono_Vars → Tela_Confirmacao
                                      └── default            → Tela_Confirmacao

Tela_Confirmacao → Criar_Case → Submit_Aprovacao (Apex invocable) → Tela_Sucesso

Tela_Erro → Tela_Selecao_Datas (loop para correção)
```

## Regras CLT implementadas

| Regra | Artigo | Lógica | Implementada? |
|---|---|---|---|
| R1 — Aviso com 30 dias | CLT art. 135 | `fxDiasAteInicio < 30` | sim |
| R2 — Saldo suficiente | CLT art. 130 | `fxDiasSolicitados > Dias_Disponiveis__c` | sim |
| R3 — Mínimo 5 dias por período | CLT art. 134 §1 | `fxDiasSolicitados < 5` | sim |
| R4 — Período concessivo | CLT art. 134 | `varDataRetorno > Periodo_Concessivo_Fim__c` | sim |
| R5 — Não iniciar em Sex/Sáb/Dom | CLT art. 134 §3 | `fxDiaSemanaInicio ∈ {1,6,7}` | sim |
| R6 — Não iniciar 2 dias antes de feriado | CLT art. 134 §3 | comparação com lista hardcoded de feriados 2026 | sim |
| R7 — Fracionamento exige 1 período ≥ 14 dias | CLT art. 134 §1 | query cruzada de Cases aprovados no mesmo aquisitivo | **não** (ver Pendências) |

## Criação do Case (`Criar_Case`)

Campos setados:

| Campo | Valor |
|---|---|
| `RecordTypeId` | `Get_RT_Pedido_Ferias.Id` |
| `OwnerId` | `varUserId` (colaborador — necessário para o record-triggered flow mandar email pro colaborador) |
| `Gestor__c` | `Get_Manager.ManagerId` (aprovador via Approval Process) |
| `Subject` | `fxAssuntoCase` |
| `Status` | `New` (entra no Business Process `Pedido_Ferias_Process`) |
| `Origin` | `Agentforce Chat` |
| `Aprovacao_Gestor__c` | `Pendente` (satisfaz entryCriteria do Approval Process) |
| `Data_Inicio_Ferias__c` | `varDataInicio` |
| `Data_Retorno_Ferias__c` | `varDataRetorno` |
| `Vender_Abono__c` | `varVenderAbono` |
| `Dias_Abono__c` | `varDiasAbono` |
| `Saldo_Ferias_Ref__c` | `Get_Saldo_Atual.Id` (consumido pelo `Case_Aprovado_Atualiza_Saldo`) |

## Submissão de aprovação

A action `Submit_Aprovacao` chama o Apex invocable `FeriasApprovalSubmitter.submit(...)`, que executa `Approval.process(new Approval.ProcessSubmitRequest())` referenciando o Approval Process `Aprovacao_Pedido_Ferias`.

Em seguida:

1. O `initialSubmissionActions` muda o `Status` do Case para `Working`.
2. O gestor recebe o pedido para aprovação (assignado via `Gestor__c`).
3. Após aprovado, `finalApprovalActions` seta `Aprovacao_Gestor__c=Aprovado` e `Status=Closed`.
4. Isso dispara `Case_Aprovado_Atualiza_Saldo`, que decrementa `Saldo_Ferias__c.Dias_Tirados__c` e envia o email via `FeriasEmailSender` (Apex invocable).

## Permission Sets

Tanto `Agentforce_RH_Colaborador` quanto `Agentforce_RH_Gestor` incluem:

- `flowAccesses`: `Agendamento_Ferias_Screen`
- `classAccesses`: `FeriasApprovalSubmitter`, `FeriasEmailSender`

## Decisões de implementação (vs. spec inicial)

- **`OwnerId = varUserId`** (não `varGestorId`). Manter o colaborador como owner é o que permite ao record-triggered flow enviar o email de aprovação para a pessoa certa. O aprovador é identificado via `Gestor__c`.
- **`Status = 'New'`** em vez de `'Pendente Aprovacao'` — aproveita o picklist standard do Case e o business process `Pedido_Ferias_Process` (New → Working → Closed), evitando criar valores novos.
- **Output binding via `<defaultValue>` + Assignment** em vez de `outputParameters`. O `outputParameters` não é aceito em screen components `InputField` no metadata format; por isso há dois assignments dedicados (`Set_Datas_Vars`, `Set_Abono_Vars`) que copiam os inputs para as variáveis.
- **Checkbox boolean com `isRequired=true`**. Salesforce obriga `isRequired=true` em boolean InputField; o default `false` resolve na prática (o usuário não precisa interagir).
- **R7 (fracionamento)** ficou fora da primeira versão — exige query cruzada de Cases anteriores do mesmo aquisitivo. Hoje o colaborador é avisado no texto de instruções; o RH valida no Approval Process.

## Testes manuais

URL para rodar em browser (autenticado no org):

```
https://sy1774623555431.my.salesforce.com/flow/Agendamento_Ferias_Screen
```

| Cenário | Input | Resultado esperado |
|---|---|---|
| Happy path | início hoje+45, retorno +59 (15 dias), saldo 30 disponível | Case criado + Approval submetido + Tela_Sucesso com protocolo |
| R1 Aviso curto | início hoje+10 | Tela_Erro com mensagem R1 |
| R2 Saldo insuficiente | 25 dias com saldo 15 | Tela_Erro R2 |
| R3 Mínimo 5 | 3 dias | Tela_Erro R3 |
| R4 Concessivo | retorno > `Periodo_Concessivo_Fim__c` | Tela_Erro R4 |
| R5 Dia da semana | início em sábado (ex. 2026-04-18) | Tela_Erro R5 |
| R6 Véspera feriado | início em 2026-12-23 (2 dias antes do Natal) | Tela_Erro R6 |
| Sem saldo | colaborador sem `Saldo_Ferias__c` vigente | Tela_Sem_Saldo |

## Pendências / melhorias futuras

1. Implementar R7 (fracionamento com 1 período ≥ 14 dias): adicionar `Get_Cases_Aquisitivo` (Get Records) e uma regra na decision.
2. Mostrar o `CaseNumber` na Tela_Sucesso em vez do `Id` — requer um `Get_Case_Criado` após `Criar_Case`.
3. Condicionar visibilidade do campo `diasAbono` ao `venderAbono = true` na Tela_Abono (visibilidade condicional por `visibilityRule`).
4. Feriados hardcoded (2026 + 2027-01-01) — em produção extrair para Custom Metadata `Feriado__mdt`.
5. Custom Action no Agentforce (Topic `Consulta_Politicas_RH` + action `Agendar_Ferias`) ainda não conectada.
