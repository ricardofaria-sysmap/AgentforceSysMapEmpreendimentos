# Embed do Agentforce na Home I-Connecta

O LWC `iConnectaAgentforceChat` carrega o pacote npm [`@salesforce/agentforce-conversation-client`](https://www.npmjs.com/package/@salesforce/agentforce-conversation-client) via **Static Resource** `AgentforceConversationClientEmbed`, em formato **IIFE** que expõe `window.embedAgentforceClient`.

No repositório, o ficheiro `force-app/main/default/staticresources/AgentforceConversationClientEmbed.js` é um **placeholder** (sem SDK), alinhado à decisão de não versionar o bundle completo. Antes de testar o chat na org, gere o JS real e faça deploy.

## 1. Gerar o bundle localmente

```bash
cd tools/agentforce-conversation-client-embed
npm install
npm run build
```

Isto sobrescreve `force-app/main/default/staticresources/AgentforceConversationClientEmbed.js` com um IIFE (~50 KB) que inclui o SDK e `@lightning-out/application`.

Versão fixada no `package.json` da pasta `tools/`. Para atualizar, altere a dependência `@salesforce/agentforce-conversation-client`, volte a correr `npm install` e `npm run build`.

## 2. Configurar o Agent Id na Home

1. Obtenha o **Id de 18 caracteres** do agente Employee publicado (Agent Builder ou lista de agentes).
2. Em **Lightning App Builder**, abra a página **I-Connecta Home**.
3. Selecione o componente **I-Connecta Agentforce Chat**.
4. Preencha **Agent Id** (obrigatório). Opcional: **Titulo do chat**, **Lightning Out 2.0 App Id**, modo flutuante, altura/largura do painel inline.
5. Guarde e ative.

## 3. Alternativa: upload manual na org

1. Gere o ficheiro `AgentforceConversationClientEmbed.js` como acima (ou numa pipeline).
2. Em **Setup → Static Resources → New**, use o nome de API **AgentforceConversationClientEmbed** (tem de coincidir com o import do LWC).
3. Faça upload do ficheiro (ou de um zip com esse `.js` na raiz) e defina **Cache Control** como **Private** se for o caso da sua política.

## 4. Referência da API de embed

A função exposta corresponde a `embedAgentforceClient` da documentação do pacote:

- `container`: elemento DOM alvo (o LWC usa um host `lwc:dom="manual"`).
- `salesforceOrigin`: o LWC envia `window.location.origin` (sessão LEX já autenticada).
- `appId`: opcional; algumas orgs exigem o Id da aplicação Lightning Out 2.0.
- `agentforceClientConfig.agentId`: obrigatório na prática.
- `agentforceClientConfig.renderingConfig`: modo `inline` (por defeito na Home) ou `floating`.

Documentação oficial: [Agentforce Conversation Client (npm README)](https://www.npmjs.com/package/@salesforce/agentforce-conversation-client) e [Agent Script / guias Agentforce](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html).

## 5. Employee Agent e pré-visualização

Employee Agents não suportam `sf agent preview` da mesma forma que Service Agents. O embed LEX usa a sessão do utilizador; smoke tests em `docs/AGENT_EMPLOYEE.md` continuam válidos para o comportamento do agente.
