public without sharing class CancelarPedidoFerias {

    @InvocableMethod(label='Cancelar Pedido de Ferias' description='Cancela o Case de Pedido de Ferias mais recente do colaborador autenticado que esteja com aprovacao Pendente. Recall do processo de aprovacao e fecha o Case com Status=Closed.')
    public static List<Result> cancelar(List<Request> requests) {
        List<Result> results = new List<Result>();
        Id userId = UserInfo.getUserId();

        Integer turns = (requests == null || requests.isEmpty()) ? 1 : requests.size();
        for (Integer i = 0; i < turns; i++) {
            Result res = new Result();
            res.success = false;

            try {
                List<Case> pendentes = [
                    SELECT Id, CaseNumber, Data_Inicio_Ferias__c, Data_Retorno_Ferias__c, Aprovacao_Gestor__c, Status
                    FROM Case
                    WHERE OwnerId = :userId
                      AND RecordType.DeveloperName = 'Pedido_Ferias'
                      AND Aprovacao_Gestor__c = 'Pendente'
                      AND Status != 'Closed'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (pendentes.isEmpty()) {
                    res.message = 'Voce nao tem nenhum pedido de ferias pendente para cancelar.';
                    results.add(res);
                    continue;
                }

                Case c = pendentes[0];

                List<ProcessInstance> piList = [
                    SELECT Id, Status
                    FROM ProcessInstance
                    WHERE TargetObjectId = :c.Id
                      AND Status = 'Pending'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!piList.isEmpty()) {
                    List<ProcessInstanceWorkitem> wis = [
                        SELECT Id FROM ProcessInstanceWorkitem
                        WHERE ProcessInstanceId = :piList[0].Id
                    ];
                    if (!wis.isEmpty()) {
                        Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
                        pwr.setWorkitemId(wis[0].Id);
                        pwr.setAction('Removed');
                        pwr.setComments('Cancelado pelo colaborador via Agentforce.');
                        Approval.process(pwr);
                    }
                }

                c.Status = 'Closed';
                c.Aprovacao_Gestor__c = 'Reprovado';
                update c;

                res.success = true;
                res.caseId = c.Id;
                res.caseNumber = c.CaseNumber;
                res.dataInicio = formatBr(c.Data_Inicio_Ferias__c);
                res.dataRetorno = formatBr(c.Data_Retorno_Ferias__c);
                res.message = 'Pedido cancelado com sucesso. Protocolo ' + c.CaseNumber + ' foi encerrado. Voce ja pode solicitar um novo agendamento de ferias.';

            } catch (Exception e) {
                res.message = 'Erro ao cancelar pedido: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    private static String formatBr(Date d) {
        if (d == null) return '';
        Datetime dt = Datetime.newInstanceGmt(d.year(), d.month(), d.day());
        return dt.format('dd/MM/yyyy');
    }

    public class Request {
        @InvocableVariable(label='Confirmacao do colaborador (true para confirmar cancelamento)')
        public Boolean confirmacao;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem')
        public String message;

        @InvocableVariable(label='Case Id cancelado')
        public Id caseId;

        @InvocableVariable(label='Case Number cancelado')
        public String caseNumber;

        @InvocableVariable(label='Data Inicio do pedido cancelado')
        public String dataInicio;

        @InvocableVariable(label='Data Retorno do pedido cancelado')
        public String dataRetorno;
    }
}
