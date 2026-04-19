# Projeto Itaú Agentforce — Demo RH / Gestão de Férias

Demo de Agentforce para o Banco Itaú focada na jornada do colaborador para gestão de férias no sistema interno **I-Connecta**. Construída em org Salesforce Developer (ou reusando a SDO do Brasal) como prova de conceito antes da entrega do ambiente definitivo.

## Arquitetura

Dois agentes colaborando no mesmo chat:

- **Agente A — Informativo**: Agentforce com Knowledge Base respondendo dúvidas sobre política de férias (CLT/PJ, saldo, regras, benefícios, home office). Topic único: `Consulta_Politicas_RH`.
- **Agente B — Transacional**: Screen Flow embutido no chat (`Agendamento_Ferias_Screen`) para agendamento formal. Coleta datas em campos estruturados, valida regras CLT, cria Case com aprovação do gestor e dispara notificações por e-mail.

```
Colaborador → Chat Embedded → Agente A (KB)
                                  ↓ (intenção de marcar)
                              Screen Flow
                                  ↓
                        Validações CLT → Case → Approval Gestor
                                                    ↓
                                    Record-Triggered Flow
                                    ├─ E-mail confirmação
                                    ├─ Atualiza Saldo_Ferias__c
                                    └─ Scheduled Path 5d → E-mail lembrete
```

## Estrutura do repositório

```
.
├── README.md                            # este arquivo
├── sfdx-project.json                    # configuração SFDX (API 66.0)
├── .forceignore
├── docs/
│   ├── ARQUITETURA.md                   # decisões e diagramas
│   ├── ROTEIRO_DEMO.md                  # script de apresentação
│   ├── REGRAS_CLT.md                    # regras de negócio implementadas
│   ├── TOPIC_AGENTE_A.md                # scope, instructions, actions
│   ├── SCREEN_FLOW.md                   # especificação detalhada do Flow
│   ├── KNOWLEDGE.md                     # metadata, artigos e categorias
│   ├── AGENT.md                         # passo-a-passo do Agent A (UI + retrieve)
│   ├── DEPLOY_ORG_BRASAL.md             # guia de deploy na org SDO do Brasal
│   └── knowledge-articles/              # conteúdo dos 5 artigos KB (markdown)
├── specs/
│   └── agent-itau-rh.yaml               # blueprint do Agent A
├── data/
│   ├── users.csv
│   └── saldo_ferias.csv
├── config/
│   ├── project-scratch-def.json
│   └── user-{marina,pedro,carlos}.json
├── scripts/
│   ├── deploy.sh                        # com suporte a --dry-run
│   ├── create-users.sh
│   ├── bootstrap-data.sh
│   ├── create-knowledge.sh              # publica os 5 artigos KB
│   ├── apex/create-knowledge.apex
│   ├── retrieve-agent.sh                # versiona Agent_Itau_RH após criação UI
│   └── retrieve.sh
└── force-app/main/default/
    ├── objects/
    │   ├── Saldo_Ferias__c/
    │   └── Case/
    ├── permissionsets/
    └── email/
```

## Pré-requisitos

- Salesforce CLI (`sf` >= 2.0)
- Org Developer ou SDO com Agentforce / Einstein habilitado
- Licenças: pelo menos 1 `Agentforce User` + 3 Standard Users

## Deploy rápido

### Em org Developer nova

```bash
sf org login web -a itau-demo
./scripts/deploy.sh itau-demo
./scripts/create-users.sh itau-demo
./scripts/bootstrap-data.sh itau-demo
./scripts/create-knowledge.sh itau-demo
# criar Agent A via UI seguindo docs/AGENT.md (5 min), depois versionar:
./scripts/retrieve-agent.sh itau-demo
```

### Reusando a org SDO do Brasal

Ver [`docs/DEPLOY_ORG_BRASAL.md`](docs/DEPLOY_ORG_BRASAL.md). Resumo:

```bash
./scripts/deploy.sh AgentforceSysmapEmpreendimentos --dry-run
./scripts/deploy.sh AgentforceSysmapEmpreendimentos
./scripts/create-users.sh AgentforceSysmapEmpreendimentos
./scripts/bootstrap-data.sh AgentforceSysmapEmpreendimentos
./scripts/create-knowledge.sh AgentforceSysmapEmpreendimentos
# Agent A via UI (docs/AGENT.md) + retrieve:
./scripts/retrieve-agent.sh AgentforceSysmapEmpreendimentos
```

## Personas de teste

| Usuário | Perfil | Regime | Papel na demo |
|---|---|---|---|
| Marina Colaboradora CLT | Standard User | CLT | protagonista |
| Pedro Colaborador PJ | Standard User | PJ | caso alternativo |
| Carlos Gestor | Standard User + Manager | — | aprovador |

## Jornadas de demo

1. **Dúvida + agendamento bem-sucedido** (Marina)
2. **Validação CLT bloqueia** (datas ruins)
3. **Dúvida PJ** (Pedro)

## Estimativa

~39h de trabalho focado (com margem: 45-47h). Ver `docs/ARQUITETURA.md` para breakdown completo.

## Responsáveis

- Ricardo Faria (SysMap)
- Luís Silva (SysMap)
- Cliente: Renzo (Itaú)
