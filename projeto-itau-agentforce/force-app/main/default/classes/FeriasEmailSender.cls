public with sharing class FeriasEmailSender {

    @InvocableMethod(label='Enviar Email Ferias' description='Envia email de confirmacao ou lembrete de ferias ao owner do Case.')
    public static void send(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;

        Set<Id> caseIds = new Set<Id>();
        for (Request r : requests) {
            if (r != null && r.caseId != null) caseIds.add(r.caseId);
        }
        if (caseIds.isEmpty()) return;

        Map<Id, Case> cases = new Map<Id, Case>([
            SELECT Id, CaseNumber, OwnerId,
                   Data_Inicio_Ferias__c, Data_Retorno_Ferias__c, Quantidade_Dias__c
            FROM Case
            WHERE Id IN :caseIds
        ]);

        Set<Id> ownerIds = new Set<Id>();
        for (Case c : cases.values()) {
            if (c.OwnerId != null && ((String) c.OwnerId).startsWith('005')) {
                ownerIds.add(c.OwnerId);
            }
        }
        Map<Id, User> ownerUsers = new Map<Id, User>([
            SELECT Id, Email, FirstName FROM User WHERE Id IN :ownerIds
        ]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Request r : requests) {
            Case c = cases.get(r.caseId);
            if (c == null) continue;
            User owner = ownerUsers.get(c.OwnerId);
            if (owner == null || String.isBlank(owner.Email)) continue;

            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            m.setToAddresses(new List<String>{ owner.Email });
            m.setSaveAsActivity(false);

            String tipo = (r.tipo == null) ? 'APROVADO' : r.tipo.toUpperCase();
            if (tipo == 'LEMBRETE') {
                m.setSubject('Lembrete: suas ferias comecam em 5 dias');
                m.setPlainTextBody(
                    'Ola ' + owner.FirstName + ',\n\n' +
                    'Este e um lembrete amigavel: suas ferias comecam em 5 dias!\n\n' +
                    'Inicio: ' + c.Data_Inicio_Ferias__c + '\n' +
                    'Retorno: ' + c.Data_Retorno_Ferias__c + '\n\n' +
                    'Checklist pre-ferias:\n' +
                    '1. Registre o handover dos projetos em aberto\n' +
                    '2. Configure resposta automatica no e-mail\n' +
                    '3. Alinhe substituto com seu gestor\n' +
                    '4. Aproveite o descanso!\n\n' +
                    'Equipe de RH - Itau'
                );
            } else {
                m.setSubject('Suas ferias foram aprovadas');
                m.setPlainTextBody(
                    'Ola ' + owner.FirstName + ',\n\n' +
                    'Suas ferias foram aprovadas pelo seu gestor.\n\n' +
                    'Protocolo: ' + c.CaseNumber + '\n' +
                    'Inicio: ' + c.Data_Inicio_Ferias__c + '\n' +
                    'Retorno: ' + c.Data_Retorno_Ferias__c + '\n' +
                    'Total de dias: ' + c.Quantidade_Dias__c + '\n\n' +
                    'Voce recebera um lembrete 5 dias antes do inicio das ferias.\n\n' +
                    'Boas ferias!\n' +
                    'Equipe de RH - Itau'
                );
            }
            emails.add(m);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails, false);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Erro ao enviar email de ferias: ' + e.getMessage());
            }
        }
    }

    public class Request {
        @InvocableVariable(label='Case Id' required=true)
        public Id caseId;

        @InvocableVariable(label='Tipo (APROVADO ou LEMBRETE)')
        public String tipo;
    }
}
