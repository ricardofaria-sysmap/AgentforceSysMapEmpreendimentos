# Scripts de bootstrap e operação

Todos os scripts aceitam como primeiro argumento o alias da org (default `itau-demo`).

## Pré-requisitos

- Salesforce CLI (`sf` >= 2.0)
- `jq` (para parsear queries)
- Org já autenticada: `sf org login web -a itau-demo`

## Ordem de execução (nova org)

```bash
# 1. Dar permissão de execução
chmod +x scripts/*.sh

# 2. Validar o deploy sem persistir
./scripts/deploy.sh itau-demo --dry-run

# 3. Deploy real
./scripts/deploy.sh itau-demo

# 4. Criar as 3 personas (Marina, Pedro, Carlos)
./scripts/create-users.sh itau-demo

# 5. Criar os 3 registros Saldo_Ferias__c
./scripts/bootstrap-data.sh itau-demo

# 6. Criar na UI: Approval Process, Screen Flow, Record-Triggered Flow,
#    Knowledge Record Type + 5 artigos, Agentforce Agent + Topic,
#    Messaging Channel + EmbeddedServiceConfig

# 7. Puxar os componentes criados via UI para versionar
./scripts/retrieve.sh itau-demo
```

## Deployando na org SDO do Brasal

Ver [`docs/DEPLOY_ORG_BRASAL.md`](../docs/DEPLOY_ORG_BRASAL.md).

```bash
./scripts/deploy.sh AgentforceSysmapEmpreendimentos --dry-run
./scripts/deploy.sh AgentforceSysmapEmpreendimentos
./scripts/create-users.sh AgentforceSysmapEmpreendimentos
./scripts/bootstrap-data.sh AgentforceSysmapEmpreendimentos
```
