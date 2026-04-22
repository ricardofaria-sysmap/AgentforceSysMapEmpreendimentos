# Agent Itau RH (Employee) — Agent Script + Employee Agent

Documenta a arquitetura **atual** do assistente de RH do I-Connecta, construído com a nova linguagem **Agent Script** (abril/2026) e rodando como **Employee Agent** dentro do LEX do colaborador autenticado.

Substitui a abordagem anterior descrita em [AGENT.md](AGENT.md) e [TOPIC_AGENTE_A.md](TOPIC_AGENTE_A.md) (Topics + GenAiPlannerBundle via UI) e em [AGENT_V2.md](AGENT_V2.md) (primeira tentativa em Agent Script, como Service Agent).

## Por que Employee Agent

O I-Connecta é um **portal interno**: o colaborador já está autenticado (SSO corporativo → Salesforce LEX). Rodar o agente como Service Agent (Messaging-based) significaria aceitar identificação por texto do chat (email/nome), o que é **inseguro num contexto bancário**: qualquer pessoa com acesso ao canal poderia se passar pelo colega e agendar férias ou consultar saldo dele.

Employee Agent resolve isso de forma determinística:

- **Identidade imutável**: `@context.userId` vem do SSO, a LLM não consegue alterá-lo
- **Sharing respeitado**: o Apex `ConsultarSaldoFerias` roda com `WITH USER_MODE` no contexto do colaborador
- **Zero atrito na UX**: não há etapa "quem é você?" — o agente já sabe
- **Gestor resolvido via `User.ManagerId`**: o `Agendamento_Ferias_Autolaunch` consulta o gestor do `$User` logado

## Arquitetura

```
force-app/main/default/
├── aiAuthoringBundles/
│   └── Agent_Itau_RH_Employee/          ← bundle ativo (Agent Script)
│       ├── Agent_Itau_RH_Employee.agent
│       └── Agent_Itau_RH_Employee.bundle-meta.xml
├── classes/
│   ├── ConsultarPoliticasRH.cls         ← busca Knowledge
│   ├── ConsultarSaldoFerias.cls         ← saldo do colaborador logado
│   ├── FeriasApprovalSubmitter.cls      ← invocada pelo Flow
│   └── FeriasEmailSender.cls
├── flows/
│   └── Agendamento_Ferias_Autolaunch.flow-meta.xml   ← regras CLT + Case + Approval
└── bots/Agent_Itau_RH_Employee/         ← metadata gerada pelo publish
```

## Contrato de segurança

Três camadas garantem que o colaborador **nunca** consiga operar em nome de outro:

### 1. Agent Script

```yaml
config:
    agent_type: "AgentforceEmployeeAgent"
    # NO default_agent_user — o agente executa como o user logado
```

- Sem variáveis linked de canal Messaging (`EndUserId`, `RoutableId`, `ContactId`) — inúteis e confundem o planner
- Sem variável mutável `ColaboradorUserId` — não há como o LLM preenchê-la a partir do chat
- Instrução explícita: *"Nunca pergunte ao colaborador por email, CPF ou User Id para se identificar — a identidade dele já é garantida pela sessão autenticada do I-Connecta."*
- As actions passam `userId = ""` / `varUserId = ""` deterministicamente

### 2. Apex (`ConsultarSaldoFerias`)

```apex
Id userId = (req == null || String.isBlank(req.userId))
    ? UserInfo.getUserId()   // ← fallback confiável (não vem do chat)
    : (Id) req.userId;

List<Saldo_Ferias__c> saldos = [
    SELECT ... FROM Saldo_Ferias__c
    WHERE Colaborador__c = :userId
    WITH USER_MODE              // ← respeita sharing rules
    ...
];
```

- Mesmo que o `.agent` mande um userId arbitrário, a `WITH USER_MODE` bloqueia acesso a registros que o colaborador logado não pode ver.

### 3. Flow (`Agendamento_Ferias_Autolaunch`)

```xml
<!-- Assignment inserido no início do fluxo -->
<assignments>
    <name>Resolver_UserId</name>
    <assignmentItems>
        <assignToReference>varUserId</assignToReference>
        <value>
            <elementReference>Formula_UserIdResolvido</elementReference>
        </value>
    </assignmentItems>
</assignments>

<formulas>
    <name>Formula_UserIdResolvido</name>
    <expression>IF(ISBLANK({!varUserId}), {!$User.Id}, {!varUserId})</expression>
</formulas>
```

Se o `.agent` passar `varUserId = ""` (o caso normal), o fluxo cai em `$User.Id` — o usuário rodando o Flow na transação. Qualquer tentativa de injeção vinda do chat é inócua porque o planner só preenche strings pré-definidas no Agent Script.

## Estrutura do Agent Script

```
system (instructions + welcome/error)
config (developer_name + agent_type Employee, SEM default_agent_user)
variables (apenas mutable de estado do fluxo: DataInicio, DataRetorno, ...)
language (pt_BR)

start_agent topic_selector          ← roteador LLM
│
├── consulta_politicas_rh           ← apex://ConsultarPoliticasRH
├── agendamento_ferias              ← apex://ConsultarSaldoFerias + flow://Agendamento_Ferias_Autolaunch
├── escalation                      ← @utils.escalate
└── ambiguous_question              ← pede clarificação
```

### Variáveis de estado (mutables)

| Variável | Tipo | Responsável pelo set |
|---|---|---|
| `DataInicio` / `DataRetorno` | string (ISO) | `capturar_datas` (`@utils.setVariables`) |
| `VenderAbono` / `DiasAbono` | bool / number | `capturar_abono` |
| `TentativasAgendamento` | number | incrementado em falha; se ≥3 → escalation |
| `UltimoCaseNumber` | string | `set` na action `executar_agendamento` |

### Flow-of-control determinístico

O subagent `agendamento_ferias` tem lógica condicional programática (`->`) antes do prompt do LLM (`|`):

```
instructions: ->
    if @variables.TentativasAgendamento >= 3:
        transition to @topic.escalation

    if @variables.UltimoCaseNumber != "":
        | [confirmação em linguagem natural com {!@variables.UltimoCaseNumber}]
    else:
        | [prompt passo-a-passo ao LLM para conduzir o agendamento]
```

Isso garante que a **escalação após 3 falhas é deterministica**, não depende da LLM decidir.

## Como testar

### Preview no LEX (único método funcional)

Employee Agents **não** podem ser previewed via `sf agent preview` da CLI — a CLI espera um userId de Messaging que Employee Agents não têm. Tentar retorna `Invalid user ID provided on start session`.

Use a UI:

1. Faça login na org (como você ou como Marina via "Login As")
2. Setup → **Agentforce** → Agent Builder → selecione `Agent Itau RH (Employee - I-Connecta)`
3. Painel **Preview** à direita — a identidade vem automaticamente do SSO

### Cenários de smoke test

| # | Utterance | Esperado |
|---|---|---|
| 1 | "Quantos dias de férias CLT eu tenho direito por ano?" | subagent `consulta_politicas_rh` → Apex `ConsultarPoliticasRH` chamado → resposta cita art. 130 CLT |
| 2 | (logado como Marina) "Quero agendar férias de 15/12 a 29/12, vender 10 dias de abono" | `consultar_saldo` retorna 30/CLT → Flow OK → Case criado → aprovação submetida |
| 3 | (logado como Pedro) "Quero começar sexta 11/12 por 15 dias" | Flow retorna `varSucesso=false` + "não pode iniciar sex/sab/dom/véspera" |
| 4 | (após 3x falhas) | `TentativasAgendamento >= 3` → transição automática para `escalation` |

## Deploy + publish

```bash
# metadata Apex + Flow (Salesforce padrão)
sf project deploy start --metadata \
    "ApexClass:ConsultarSaldoFerias" \
    "ApexClass:ConsultarPoliticasRH" \
    "Flow:Agendamento_Ferias_Autolaunch" \
    -o <alias>

# agent script (API do Agentforce)
sf agent validate authoring-bundle --api-name Agent_Itau_RH_Employee -o <alias>
sf agent publish  authoring-bundle --api-name Agent_Itau_RH_Employee -o <alias>
sf agent activate                   --api-name Agent_Itau_RH_Employee -o <alias>
```

> **Nota**: `agent_type` é imutável após o primeiro publish. Se precisar alternar entre Service ↔ Employee, crie um bundle novo com outro api-name. É por isso que mantemos `Agent_Itau_RH_V2` (Service Agent, desativado) como histórico em paralelo.

## Referências

- [Agent Script | Salesforce Developer Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html)
- [Variables | Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-variables.html)
- Decisão de arquitetura registrada no commit de migração (`feat(itau/agent): migrar para Employee Agent`)
