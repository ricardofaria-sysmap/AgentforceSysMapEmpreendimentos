# Roteiro da Demo — Agentforce RH Itaú

**Duração:** 20 minutos (15 min de demo + 5 min Q&A)
**Audiência:** Renzo (Itaú) + stakeholders
**Apresentadores:** Ricardo (condução técnica) + Luís (contexto de negócio)

## Estrutura

### Abertura (2 min) — Luís
- Contexto: evolução do I-Connecta com Agentforce
- Escopo da demo: jornada de férias como piloto, escalável para outras jornadas de RH (folha, benefícios, desligamento)
- Promessa: ver em funcionamento antes do acesso formal ao ambiente do Itaú

### Demo 1 — Dúvida simples (3 min) — Ricardo
Persona: **Marina**, colaboradora CLT
1. Abrir chat I-Connecta simulado
2. Perguntar: **"Posso dividir minhas férias em 3 partes?"**
3. Mostrar agente consultando KB e respondendo com citação da fonte
4. Destacar: resposta rápida, sem esperar RH, linguagem natural

### Demo 2 — Diferença CLT vs PJ (2 min) — Ricardo
Persona: **Pedro**, PJ
1. Perguntar: **"Sou PJ, tenho direito a 30 dias de férias?"**
2. Agente detecta regime e traz regra contratual distinta
3. Destacar: mesmo agente, contextualização por persona

### Demo 3 — Home I-Connecta + Agendamento bem-sucedido (6 min) — Ricardo
Persona: **Marina** (CLT)
1. Abrir o app **I-Connecta** pelo App Launcher → aterrissa na **Home** com o LWC `saldoFeriasCard` ("Você tem 30 dias disponíveis")
2. Mostrar rapidamente os atalhos: Meus Pedidos, Feriados 2026, Chat RH
3. Voltar ao chat do agent: **"Quantos dias eu tenho disponíveis?"** → agente consulta e mostra
4. **"Quero marcar férias de 15/09 a 29/09, sem vender abono"** → agente invoca **Autolaunched Flow** `Agendamento_Ferias_Autolaunch`
5. Agente confirma em linguagem natural: *"Pedido 00001234 enviado ao seu gestor Carlos."*
6. Mostrar o Case criado com Status "Pendente Aprovação" (lista "Meus Pedidos de Ferias")
7. Alternativa UI — abrir a **Global Quick Action "Agendar Ferias"** (ou botão "Agendar" do saldoFeriasCard): destacar que o **Screen Flow** é a mesma lógica para quem prefere formulário
8. Trocar para **Carlos** (gestor): abrir Approval Request, aprovar
9. Voltar para Marina: mostrar e-mail de confirmação recebido
10. Destacar:
    - Dois canais (chat + UI) compartilhando validação e Approval Process
    - Determinismo: datas tipadas, não strings do LLM
    - Aprovação roteada automaticamente ao manager
    - E-mail disparado + lembrete agendado D-5

### Demo 4 — Validação CLT bloqueando (2 min) — Ricardo
Persona: Marina novamente
1. No chat: **"Quero tirar 3 dias de férias na próxima sexta"**
2. Agente invoca o Autolaunched Flow, que retorna `varSucesso=false` + `varMensagemErro` com a regra CLT violada
3. Agente repassa o texto literal: *"Não foi possível. O período mínimo por segmento é de 5 dias corridos..."*
4. Marina corrige no chat com novas datas → fluxo segue com sucesso
5. Destacar:
   - Regras CLT em Flow determinístico, não na cabeça do LLM
   - Mensagem de erro é consistente independente do canal (chat ou Screen Flow)

### Encerramento (1 min) — Luís
- Recapitular: 2 agentes, 1 experiência integrada
- Escopo de produção: multiplicar padrão para outras jornadas (reembolsos, folha, saúde)
- Próximos passos e timeline

## Slides de apoio sugeridos

1. **Capa** — Agentforce RH Itaú | I-Connecta 2.0
2. **Desafio** — % de tickets de RH que são dúvidas repetitivas (dado do Itaú, se disponível)
3. **Arquitetura** — o diagrama de [ARQUITETURA.md](ARQUITETURA.md#diagrama-de-componentes)
4. **Personas da demo** — Marina, Pedro, Carlos
5. **Métricas alvo** — redução de TMA, auto-atendimento, compliance CLT
6. **Roadmap** — onde mais aplicar o padrão (reembolsos, folha, onboarding)
7. **Próximos passos** — timeline, acessos, sprint 0

## Antes da demo (checklist dia D-1)

- [ ] Org funcional e com acesso externo (sandbox URL)
- [ ] 3 usuários com senhas redefinidas (Marina, Pedro, Carlos)
- [ ] Saldo_Ferias__c populado nos 3 cenários
- [ ] Feriado__c com seed 2026/2027 carregado (`scripts/load-feriados.sh`)
- [ ] Custom app **I-Connecta** visível no App Launcher para colaborador e gestor
- [ ] FlexiPage `I_Connecta_Home` renderizando o LWC `saldoFeriasCard` para o usuário Marina
- [ ] Nenhum Case aberto que possa disparar e-mail indesejado
- [ ] Agent Builder: Topics `Consulta_Politicas_RH` e `Agendamento_Ferias` ativos, preview testado
- [ ] Chat web acessível (URL pública do Embedded Service) OU agente Preview aberto
- [ ] Email Deliverability = "All email" na org
- [ ] Janelas/abas pré-abertas: App I-Connecta (Marina), Approval Request (Carlos), inbox simulada

## Plano B

- Se Agentforce não responder: usar a **Global Quick Action "Agendar Ferias"** (Screen Flow) e abrir o Knowledge Article direto
- Se Autolaunched Flow falhar no chat: trocar para Screen Flow via Quick Action (lógica equivalente)
- Se Screen Flow travar: mostrar gravação pré-feita
- Se Approval não disparar: abrir Case manualmente e mostrar o Record-Triggered Flow no debug log
