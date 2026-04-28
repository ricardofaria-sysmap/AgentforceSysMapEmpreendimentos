@IsTest
private class CancelarPedidoFeriasTest {

    private static User criarColaborador() {
        User u = new User(
            FirstName = 'Cancel',
            LastName = 'Tester',
            Email = 'cancel.tester@itau.com.invalid',
            Username = 'cancel.tester@itau.com.invalid.' + System.currentTimeMillis(),
            Alias = 'cantst',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert u;
        return u;
    }

    @IsTest
    static void cancelaCasePendente() {
        User u = criarColaborador();
        Id rtId = [SELECT Id FROM RecordType WHERE SobjectType='Case' AND DeveloperName='Pedido_Ferias' LIMIT 1].Id;
        Case c;
        System.runAs(u) {
            c = new Case(
                RecordTypeId = rtId,
                OwnerId = u.Id,
                Subject = 'Pedido de Ferias Test',
                Status = 'New',
                Origin = 'Agentforce Chat',
                Aprovacao_Gestor__c = 'Pendente',
                Data_Inicio_Ferias__c = Date.today().addDays(45),
                Data_Retorno_Ferias__c = Date.today().addDays(50)
            );
            insert c;

            Test.startTest();
            CancelarPedidoFerias.Request req = new CancelarPedidoFerias.Request();
            req.confirmacao = true;
            List<CancelarPedidoFerias.Result> res = CancelarPedidoFerias.cancelar(
                new List<CancelarPedidoFerias.Request>{ req }
            );
            Test.stopTest();

            System.assertEquals(1, res.size());
            System.assertEquals(true, res[0].success, 'Cancelamento deveria ter sucesso');
            System.assertEquals(c.Id, res[0].caseId);
        }

        Case after = [SELECT Status, Aprovacao_Gestor__c FROM Case WHERE Id = :c.Id];
        System.assertEquals('Closed', after.Status);
        System.assertEquals('Reprovado', after.Aprovacao_Gestor__c);
    }

    @IsTest
    static void retornaSemPedidoQuandoNaoExiste() {
        User u = criarColaborador();
        System.runAs(u) {
            Test.startTest();
            List<CancelarPedidoFerias.Result> res = CancelarPedidoFerias.cancelar(
                new List<CancelarPedidoFerias.Request>{ new CancelarPedidoFerias.Request() }
            );
            Test.stopTest();
            System.assertEquals(false, res[0].success);
            System.assert(res[0].message.contains('nao tem'));
        }
    }
}
