# App I-Connecta — Experiência do Colaborador

O app **I-Connecta** (`I_Connecta`) é a simulação da intranet do Itaú dentro do Salesforce Developer Org. Ele concentra todos os pontos de contato da jornada de férias: consulta de saldo, abertura de pedido, acompanhamento, feriados e chat com o Agentforce.

## Visão geral

| Item | Valor |
|---|---|
| API Name | `I_Connecta` |
| Label | `I-Connecta` |
| Tipo | Lightning App (`CustomApplication`) |
| Form Factor | Large (desktop) |
| Navegação | Standard |
| Home | FlexiPage `I_Connecta_Home` (template `flexipage:defaultAppHomeTemplate`) |

## Estrutura de navegação

Tabs na barra de navegação (na ordem):

1. **Home** — tab customizada `I_Connecta_Home` apontando para a FlexiPage de home
2. **Saldo de Ferias** — tab do objeto `Saldo_Ferias__c`
3. **Feriados** — tab do objeto `Feriado__c`
4. **Cases** — tab padrão `standard-Case` (com list view `Meus_Pedidos_Ferias` como default para o perfil colaborador)

> Knowledge não está na app navigation diretamente por limitação de Lightning Apps em Developer Orgs. Os artigos são consumidos via o Topic `Consulta_Politicas_RH` do agent.

## FlexiPage `I_Connecta_Home`

Template: `flexipage:defaultAppHomeTemplate` (single-region `main`).

Componentes na região `main` (nesta ordem):

1. **Welcome banner** (`flexipage:richText`) — saudação e branding I-Connecta
2. **LWC `saldoFeriasCard`** — dashboard visual de férias do usuário
3. **Quick links** (`flexipage:richText`) — atalhos para Meus Pedidos, Feriados, Políticas RH
4. **Chat RH CTA** (`flexipage:richText`) — banner convidando para abrir o chat do Agent

### LWC `saldoFeriasCard`

- Ficheiros: `force-app/main/default/lwc/saldoFeriasCard/{.html,.js,.css,.js-meta.xml}`
- Apex backend: `SaldoFeriasController.getSaldoVigente()` — retorna `Saldo_Ferias__c` vigente do usuário corrente (cacheable)
- Exibe: período aquisitivo, dias de direito, dias tirados, dias disponíveis, dias de abono vendidos, gráfico donut de progresso
- Botão **Agendar Ferias** → navega para o Screen Flow `Agendamento_Ferias_Screen` via `lightning/navigation`

## Global Quick Action `Agendar_Ferias`

- API Name: `Agendar_Ferias`
- Tipo: Global Action → Flow
- Flow invocado: `Agendamento_Ferias_Screen`
- Disponível no publisher global em qualquer página (Home, Cases, Saldo etc.)

## List View `Meus_Pedidos_Ferias`

- Objeto: `Case`
- Fullname: `Meus_Pedidos_Ferias`
- Scope: `Mine`
- Filtro: `CASE.SUBJECT contains "Pedido de Ferias"`
- Colunas: Case Number, Subject, `Data_Inicio_Ferias__c`, `Data_Retorno_Ferias__c`, `Quantidade_Dias__c`, `Aprovacao_Gestor__c`, Status, Created Date

## Permission Sets

Ambas as permission sets foram atualizadas para suportar a app:

- `Agentforce_RH_Colaborador` — acesso read/create a `Saldo_Ferias__c`, `Feriado__c` (read), `Case`; flow access ao `Agendamento_Ferias_Screen` + `Agendamento_Ferias_Autolaunch`; class access a `SaldoFeriasController`; tabs `I_Connecta_Home`, `Saldo_Ferias__c`, `Feriado__c`, `standard-Case`; visibility do app `I_Connecta`
- `Agentforce_RH_Gestor` — permissões acima + edit/delete em `Feriado__c` + acesso ao Approval Inbox

## Deploy checklist

1. Deploy padrão via `sfdx force:source:deploy` do `force-app` (tudo incluso)
2. Após deploy, atribuir a permission set:
   ```bash
   sf org assign permset -n Agentforce_RH_Colaborador -o <org>
   ```
3. Logar como Marina, abrir App Launcher → I-Connecta → confirmar Home com `saldoFeriasCard` populado
4. Testar Quick Action "Agendar Ferias" no publisher global
5. Abrir Feriados → conferir que `Ano = 2026` mostra os seeds de `data/feriados-2026.csv`

## Pontos de atenção

- A Utility Bar (`I_Connecta_UtilityBar`) foi **removida** do escopo inicial por limitações do `flexipage:flowComponent` em Developer Orgs. Caso queira reativar, configurar manualmente via App Manager → Edit App → Utility Items.
- O FlexiPage é um `AppPage`, portanto só aparece como home do app I-Connecta; não é a home global da org.
- O LWC `saldoFeriasCard` assume que o usuário logado tem um único `Saldo_Ferias__c` com `Status__c = 'Vigente'`. Caso não exista, o card mostra um empty state com CTA para "Agendar Ferias".
