# Dados de teste

## Arquivos

- `users.csv` — 3 users de demo (Marina CLT, Pedro PJ, Carlos Gestor)
- `saldo_ferias.csv` — 3 registros de `Saldo_Ferias__c` cobrindo cenários distintos

## Ordem de import

1. **Users** primeiro (via Setup ou `sf org create user -f config/user-*.json`)
2. **Permission Set** `Agentforce_RH_Colaborador` atribuído a Marina e Pedro
3. **Permission Set** `Agentforce_RH_Gestor` atribuído a Carlos
4. **Saldo_Ferias__c** via `scripts/bootstrap-data.sh`

## Cenários representados

| Persona | Regime | Dias direito | Tirados | Disponíveis | Cenário |
|---|---|---|---|---|---|
| Marina | CLT | 30 (≤5 faltas) | 0 | 30 | saldo cheio — happy path |
| Pedro | PJ | 20 úteis | 5 | 15 | PJ com dias já usados |
| Carlos | CLT | 30 | 20 | 10 | pouco saldo — teste de limite |
