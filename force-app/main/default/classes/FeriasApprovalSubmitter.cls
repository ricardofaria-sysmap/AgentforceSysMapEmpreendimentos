public with sharing class FeriasApprovalSubmitter {

    public static final String PROCESS_NAME = 'Aprovacao_Pedido_Ferias';

    @InvocableMethod(label='Submeter Pedido de Ferias para Aprovacao' description='Submete um Case para o processo de aprovacao Aprovacao_Pedido_Ferias.')
    public static List<Result> submit(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) return results;

        for (Request req : requests) {
            Result res = new Result();
            res.success = false;

            if (req == null || req.caseId == null) {
                res.errorMessage = 'caseId obrigatorio.';
                results.add(res);
                continue;
            }

            try {
                Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
                psr.setObjectId(req.caseId);
                psr.setProcessDefinitionNameOrId(PROCESS_NAME);
                psr.setSkipEntryCriteria(false);
                psr.setComments(
                    String.isBlank(req.comments)
                        ? 'Submetido via Agentforce (Screen Flow Agendamento_Ferias_Screen).'
                        : req.comments
                );
                Approval.ProcessResult pr = Approval.process(psr);
                res.success = pr.isSuccess();
                res.instanceStatus = pr.getInstanceStatus();
                res.instanceId = pr.getInstanceId();
                if (!pr.isSuccess() && pr.getErrors() != null && !pr.getErrors().isEmpty()) {
                    res.errorMessage = pr.getErrors()[0].getMessage();
                }
            } catch (Exception e) {
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Case Id' required=true)
        public Id caseId;

        @InvocableVariable(label='Comentario de submissao')
        public String comments;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Instance Status')
        public String instanceStatus;

        @InvocableVariable(label='Instance Id')
        public String instanceId;

        @InvocableVariable(label='Mensagem de Erro')
        public String errorMessage;
    }
}
