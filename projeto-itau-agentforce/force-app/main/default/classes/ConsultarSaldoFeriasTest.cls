@IsTest
private class ConsultarSaldoFeriasTest {

    @IsTest
    static void testNullRequest() {
        Test.startTest();
        List<ConsultarSaldoFerias.Result> res = ConsultarSaldoFerias.consultar(null);
        Test.stopTest();
        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }

    @IsTest
    static void testEmptyRequest() {
        Test.startTest();
        List<ConsultarSaldoFerias.Result> res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>());
        Test.stopTest();
        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }

    @IsTest
    static void testSemSaldo() {
        ConsultarSaldoFerias.Request req = new ConsultarSaldoFerias.Request();
        req.userId = UserInfo.getUserId();

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
        System.assert(res[0].message != null);
    }

    @IsTest
    static void testComSaldoVigente() {
        User u = new User(
            FirstName = 'Test',
            LastName = 'User SaldoFerias',
            Email = 'saldo.ferias.test@itau.com.invalid',
            Username = 'saldo.ferias.test@itau.com.invalid.' + System.currentTimeMillis(),
            Alias = 'sftest',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert u;

        Saldo_Ferias__c s = new Saldo_Ferias__c(
            Colaborador__c = u.Id,
            Regime_Contratacao__c = 'CLT',
            Periodo_Aquisitivo_Inicio__c = Date.today().addYears(-1),
            Dias_Tirados__c = 0,
            Faltas_Injustificadas__c = 0,
            Dias_Abono_Vendidos__c = 0,
            Status__c = 'Vigente'
        );
        insert s;

        ConsultarSaldoFerias.Request req = new ConsultarSaldoFerias.Request();
        req.userId = u.Id;

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ req });
        }
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(true, res[0].success, 'Deveria encontrar saldo vigente');
        System.assertEquals('CLT', res[0].regime);
        System.assertEquals(30, res[0].diasDireito, 'Formula Dias_Direito__c deve ser 30 para CLT com 0 faltas');
        System.assertEquals('Vigente', res[0].status);
    }

    @IsTest
    static void testUserIdVazioUsaLogado() {
        ConsultarSaldoFerias.Request req = new ConsultarSaldoFerias.Request();

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
    }

    @IsTest
    static void testUserIdInvalido() {
        ConsultarSaldoFerias.Request req = new ConsultarSaldoFerias.Request();
        req.userId = 'not-an-id';

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }
}
