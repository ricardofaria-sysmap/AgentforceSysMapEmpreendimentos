public with sharing class IniciarHandoffAgendamento {

    private static final String MENSAGEM_PADRAO_USUARIO =
        'Calendario liberado abaixo do chat. Selecione a data de inicio e a data de retorno das ferias.';

    @InvocableMethod(
        label='Iniciar Handoff Calendario Ferias'
        description='Publica o Platform Event Handoff_Calendario_RH__e para sinalizar ao LWC do Screen Flow que o colaborador confirmou a intencao de agendar ferias. Use SOMENTE apos confirmacao explicita do colaborador no chat.'
        callout=false
    )
    public static List<Result> iniciar(List<Request> requests) {
        List<Result> out = new List<Result>();

        Integer turns = (requests == null || requests.isEmpty()) ? 1 : requests.size();
        Id userId = UserInfo.getUserId();

        for (Integer i = 0; i < turns; i++) {
            Request req = (requests != null && i < requests.size()) ? requests.get(i) : null;
            Result r = new Result();
            r.success = false;

            try {
                String msg = (req != null && String.isNotBlank(req.mensagem))
                    ? req.mensagem
                    : MENSAGEM_PADRAO_USUARIO;
                String sessionId = (req != null) ? req.sessionId : null;

                Handoff_Calendario_RH__e evt = new Handoff_Calendario_RH__e(
                    User_Id__c = String.valueOf(userId),
                    Session_Id__c = sessionId,
                    Mensagem__c = msg.length() > 255 ? msg.substring(0, 255) : msg
                );

                Database.SaveResult sr = EventBus.publish(evt);
                r.success = sr.isSuccess();
                r.userId = String.valueOf(userId);

                if (r.success) {
                    r.message = MENSAGEM_PADRAO_USUARIO;
                } else {
                    String firstError = sr.getErrors().isEmpty()
                        ? 'Erro desconhecido ao publicar Platform Event.'
                        : sr.getErrors().get(0).getMessage();
                    r.message = 'Nao consegui liberar o calendario agora. Tente novamente em instantes. (' + firstError + ')';
                }
            } catch (Exception e) {
                r.message = 'Erro ao liberar calendario: ' + e.getMessage();
            }

            out.add(r);
        }

        return out;
    }

    public class Request {
        @InvocableVariable(
            label='Mensagem opcional do agente'
            description='Texto opcional enviado pelo agente para o LWC. Se vazio, usa mensagem padrao.'
            required=false
        )
        public String mensagem;

        @InvocableVariable(
            label='Session Id (opcional)'
            description='Identificador opcional da sessao/aba para correlacionar com o LWC.'
            required=false
        )
        public String sessionId;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem para o usuario')
        public String message;

        @InvocableVariable(label='User Id usado na publicacao')
        public String userId;
    }
}
