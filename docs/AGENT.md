# Agent A (Informativo) — Agent Itau RH

Este documento descreve a configuração do **Agent A** (assistente virtual de RH do I-Connecta). O agente cobre dois tópicos:

1. **Consulta de Políticas de RH** — responde dúvidas consultando a base de Knowledge (RecordType `Politica_RH`, Data Categories `Topicos_RH`).
2. **Agendamento de Férias** — invoca o **Autolaunched Flow** `Agendamento_Ferias_Autolaunch` para o colaborador marcar férias via conversa.

> **Estratégia híbrida (Escopo D):** o agent usa o flow _autolaunched_ (coleta inputs por linguagem natural). Para a experiência de formulário guiado, o mesmo `Agendamento_Ferias_Screen` está exposto como **Global Quick Action** (`Agendar_Ferias`) e no botão "Agendar" do card de saldo na Home I-Connecta.

## Por que UI + retrieve (e não deploy direto)?

Tentei criar este agente 100% via metadata (`Bot`, `GenAiPlannerBundle`, `GenAiPlugin`), mas esbarrei em dois limites da org Brasal SDO:

1. **`sf agent create`** exige o prompt Einstein `einstein_gpt__aiAssistAgentGen`, que não está habilitado na SDO.
2. **Deploy puro** falha em `localActions` do tipo `flow` para **Screen Flows** — a validação do `GenAiPlannerBundle` exige que a action já exista como "Agent Action" publicada, o que só o Agent Builder UI faz sob o capô (ele cria um wrapper de action antes de vincular ao topic).

**Abordagem prática:** criar o agent via UI (5 min), depois rodar `scripts/retrieve-agent.sh` para versionar o metadata resultante no git. O spec `specs/agent-itau-rh.yaml` e este documento garantem reprodutibilidade.

## Blueprint do agent

Arquivo: `specs/agent-itau-rh.yaml`

- **Label:** Agent Itau RH
- **API Name:** `Agent_Itau_RH`
- **Type:** Internal (Employee)
- **Tone:** Formal
- **Company:** Banco Itau
- **Role (prompt raiz):**

  > Você é o assistente virtual de RH do Banco Itaú no I-Connecta. Ajuda colaboradores com duas necessidades: (1) responder dúvidas de política de férias (CLT/PJ, abono, fracionamento), benefícios e home office consultando EXCLUSIVAMENTE a base de Knowledge interna (RecordType `Politica_RH`, Data Categories `Topicos_RH`); (2) agendar férias de forma estruturada através do Screen Flow `Agendamento_Ferias_Screen`, que coleta datas em campos de formulário e valida as regras CLT automaticamente.
  >
  > REGRAS: Nunca invente regras. Sempre cite a fonte legal (CLT art. XXX). Nunca prometa aprovação - isso depende do gestor via Approval Process. Tom formal e acolhedor.

## Passo a passo na UI Agent Builder

### 1. Criar o agent vazio

1. **Setup → Agents → New Agent**.
2. Escolha o template **Custom Agent** (ou "Build your own").
3. Name: `Agent Itau RH` — API Name: `Agent_Itau_RH`.
4. Type: **Internal**, Tone: **Formal**, Company: `Banco Itau`.
5. Cole o Role do blueprint acima.
6. Clique **Save**.

### 2. Configurar o Topic 1: Consulta Políticas RH

1. Aba **Topics** → **New Topic**.
2. Topic Label: `Consulta Politicas RH` — API Name: `Consulta_Politicas_RH`.
3. **Classification Description:**

   > Responde dúvidas sobre políticas de RH do Itaú (férias CLT/PJ, abono pecuniário, fracionamento, benefícios durante férias, home office) consultando exclusivamente os artigos publicados na base de Knowledge Itaú RH. Sempre cita fonte legal.

4. **Scope:**

   > Você é especialista em políticas internas de RH do Banco Itaú (I-Connecta). Responde dúvidas sobre férias (CLT e PJ), abono pecuniário, fracionamento, benefícios durante as férias e política de home office, consultando EXCLUSIVAMENTE os artigos publicados na base de Knowledge com RecordType `Politica_RH` e Data Category Group `Topicos_RH`.
   >
   > **PODE:** consultar e resumir políticas documentadas; citar a fonte legal; explicar regras de cálculo; redirecionar para o tópico de agendamento quando houver intenção de marcar férias.
   >
   > **NÃO PODE:** inventar regras não documentadas; prometer aprovação de férias; responder fora do escopo RH; informar dados de outros colaboradores.

5. **Instructions** (adicione uma por uma):
   - *"Sempre consulte a base de Knowledge antes de responder qualquer pergunta sobre política de RH. Nunca invente regras. Se a informação não estiver na base, diga que não encontrou e sugira transferir para o atendimento humano."*
   - *"Ao citar uma regra, sempre informe a fonte legal (ex: 'conforme art. 143 CLT') e ofereça o link do artigo quando disponível nas citações. Priorize clareza sobre completude: responda a dúvida específica do colaborador em poucos parágrafos, não despeje o artigo inteiro."*
   - *"Quando o colaborador demonstrar intenção de MARCAR férias (ex: 'quero tirar férias', 'preciso agendar minhas férias em setembro'), encerre este tópico e transfira para o tópico Agendamento de Férias."*
   - *"Temas cobertos: férias CLT (regras gerais, aquisitivo, concessivo, 1/3, pagamento em dobro), fracionamento, abono pecuniário, CLT x PJ no Itaú, benefícios durante as férias, política de home office. Fora disso, informe que este assistente é especializado apenas nesses temas."*

6. **Actions** → **New Action → From Agent Asset Library**:
   - Selecione **Answer Questions with Knowledge** (standard).
   - Rename (opcional): `Consultar Politicas de RH`.
   - Progress indicator message: `Consultando base de políticas de RH`.
   - Salve.

7. **Save Topic**.

### 3. Configurar o Topic 2: Agendamento de Férias

1. **New Topic**.
2. Label: `Agendamento de Ferias` — API Name: `Agendamento_Ferias`.
3. **Classification Description:**

   > Quando o colaborador quer MARCAR / AGENDAR férias, invoca o Screen Flow `Agendamento_Ferias_Screen` que coleta datas em campos estruturados, valida as regras CLT, cria o Case de Pedido de Férias e submete ao Approval Process do gestor.

4. **Scope:**

   > Você é responsável pelo agendamento formal de férias via I-Connecta. Quando o colaborador manifestar intenção de MARCAR férias, invoca o Screen Flow `Agendamento_Ferias_Screen`, que colhe datas de início e retorno em campos estruturados, permite indicar venda de abono pecuniário (até 10 dias), valida automaticamente todas as regras CLT, cria um Case do tipo "Pedido de Férias" e submete ao Approval Process com o gestor direto.
   >
   > **NÃO PODE:** criar Case diretamente sem passar pelo Screen Flow; alterar saldo de outro colaborador; aprovar em nome do gestor; coletar datas em linguagem livre — sempre use o Screen Flow.

5. **Instructions:**
   - *"Quando o colaborador demonstrar intenção de MARCAR/AGENDAR férias, invoque a action Agendar Férias imediatamente. Não faça perguntas sobre datas em linguagem natural — o Screen Flow tem formulário próprio. Antes de invocar, apenas confirme em uma frase: 'Perfeito, vou abrir o formulário de agendamento de férias para você. Um instante...'"*
   - *"O Screen Flow valida automaticamente as regras CLT (antecedência 30 dias, saldo, mínimo 5 dias, início não pode ser sexta/sábado/domingo, 2 dias antes de feriado, período concessivo, limite de abono 1/3). Se o colaborador violar alguma regra, o próprio Screen Flow mostra a tela de erro. Você NÃO precisa validar datas no chat."*
   - *"Após o colaborador concluir o Flow com sucesso, o sistema cria um Case, submete ao Approval Process do gestor direto, envia email de confirmação quando aprovar, e dispara lembrete 5 dias antes do início. Pergunte se há mais alguma dúvida ou encerre educadamente."*

6. **Actions** → **New Action → From Flow**:
   - Selecione o Flow **`Agendamento_Ferias_Autolaunch`** (autolaunched, não o Screen Flow).
   - Action Label: `Agendar Ferias` — API Name: `Agendar_Ferias`.
   - **Inputs** a coletar em conversa:
     - `varUserId` → mapeie para `$User.Id` (contexto do usuário autenticado, **não pergunte**).
     - `varDataInicio` → pergunte em linguagem natural ("Qual a data de início desejada?") — tipo Date.
     - `varDataRetorno` → pergunte em linguagem natural ("E a data de retorno ao trabalho?") — tipo Date.
     - `varVenderAbono` → pergunte se quer vender abono pecuniário (default `false`).
     - `varDiasAbono` → se `varVenderAbono=true`, pergunte quantos dias (default `0`).
   - **Outputs** a expor ao planner:
     - `varSucesso` (Boolean): orienta a mensagem final.
     - `varMensagemErro` (String): se `varSucesso=false`, o agent repassa esse texto literalmente ao colaborador (contém a regra CLT violada).
     - `varCaseId` / `varCaseNumber`: use no feedback de sucesso ("Pedido 00001234 enviado ao seu gestor").
   - Instructions:
     - *"Invoke this action when the user expresses intent to schedule vacation ('tirar ferias', 'agendar ferias', 'marcar ferias'). Always pass `varUserId = $User.Id`."*
     - *"If `varSucesso = false`, repeat `varMensagemErro` verbatim to the user — it already explains the CLT rule that was violated. Do not rephrase or invent extra rules."*
     - *"If `varSucesso = true`, congratulate and mention the Case number (`varCaseNumber`), reminding that the manager will receive the approval request and an email will confirm the outcome."*
   - Salve.

7. **Save Topic**.

### 4. Ativar e testar

1. Volte ao overview do agent → **Activate**.
2. Aba **Conversation Preview** → teste:
   - *"Quantos dias de férias eu tenho direito?"* → deve invocar Knowledge search no topic `Consulta_Politicas_RH`.
   - *"Quero marcar férias de 15/09 a 24/09, vendendo 10 dias de abono."* → deve coletar as datas, invocar `Agendamento_Ferias_Autolaunch` e retornar confirmação com Case number.
   - *"Quero tirar 3 dias de férias na próxima semana."* → deve receber a mensagem de erro CLT ("mínimo 5 dias" e/ou "antecedência 30 dias").
3. Se o Flow `Agendamento_Ferias_Autolaunch` não aparecer na lista de Flows disponíveis para Action, confirme que:
   - Está ativo (`sf data query -q "SELECT IsActive FROM FlowDefinitionView WHERE ApiName='Agendamento_Ferias_Autolaunch'"`).
   - Tem `<environments>Default</environments>` (já configurado no XML).
   - O usuário do agent (botUser) tem a permission set `Agentforce_RH_Colaborador` para executar o Flow (já inclui `Agendamento_Ferias_Autolaunch` + `SaldoFeriasController`).

### 5. Versionar o metadata

Depois de ativo e testado:

```bash
./scripts/retrieve-agent.sh <alias-da-org>
git add force-app/main/default/bots/ \
        force-app/main/default/genAiPlannerBundles/ \
        force-app/main/default/genAiPlugins/
git commit -m "feat: agent Itau RH configurado (Consulta Politicas + Agendamento Ferias)"
```

A partir daí, o agent é reproduzível: um novo deploy em outra org + `./scripts/retrieve-agent.sh` na org destino após qualquer ajuste pela UI.

## Troubleshooting

### O topic Consulta_Politicas_RH não encontra artigos

- Verifique: `sf data query -q "SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus='Online' AND Language='pt_BR' AND RecordType.DeveloperName='Politica_RH'"` → deve retornar 5.
- Confirme Data Category Group `Topicos_RH` ativo (Setup → Data Categories).
- Confirme que o botUser tem acesso a Knowledge via permission set.

### A action Agendar_Ferias não abre o formulário

- Confirme que o Flow está ativo.
- Verifique se `varUserId` foi mapeado corretamente para `$User.Id` ou context equivalente.
- Teste o Flow isoladamente no Flow Builder.

### Citações não aparecem nas respostas de Knowledge

- Na config do agent, habilite **Citations Enabled** (no topo do Bot).
- Verifique se `AnswerQuestionsWithKnowledge` tem `citationsEnabled: true` no input schema.

## Próximos passos pós-configuração

- [ ] Adicionar uma **Custom Action Apex** `Consultar_Saldo_Ferias` que retorna o `Saldo_Ferias__c` do colaborador autenticado para o agent incluir no contexto das respostas.
- [ ] Criar **Deploy-time validations** para garantir que os 5 artigos de Knowledge estão publicados antes de ativar o agent.
- [ ] Integrar com **Messaging for Web** para expor o agent num portal externo (opcional para demo).
