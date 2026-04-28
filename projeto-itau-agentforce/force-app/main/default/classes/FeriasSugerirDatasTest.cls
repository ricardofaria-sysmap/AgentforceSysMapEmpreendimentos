@IsTest
private class FeriasSugerirDatasTest {

    private static User criarColaborador() {
        User u = new User(
            FirstName = 'Sug',
            LastName = 'Datas',
            Email = 'sug.datas@itau.com.invalid',
            Username = 'sug.datas@itau.com.invalid.' + System.currentTimeMillis(),
            Alias = 'sugd',
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
    static void retornaSugestoesQuandoSaldoOk() {
        User u = criarColaborador();
        System.runAs(u) {
            insert new Saldo_Ferias__c(
                Colaborador__c = u.Id,
                Regime_Contratacao__c = 'CLT',
                Periodo_Aquisitivo_Inicio__c = Date.today().addYears(-1),
                Dias_Tirados__c = 0,
                Faltas_Injustificadas__c = 0,
                Dias_Abono_Vendidos__c = 0,
                Status__c = 'Vigente'
            );
        }

        FeriasSugerirDatas.Request req = new FeriasSugerirDatas.Request();
        req.userId = u.Id;
        req.dataInicioPretendida = Date.today().addDays(45);
        req.diasSolicitados = 5;

        Test.startTest();
        List<FeriasSugerirDatas.Result> res = FeriasSugerirDatas.suggest(
            new List<FeriasSugerirDatas.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertNotEquals(null, res[0].datasSugeridas);
        System.assert(res[0].datasSugeridas.length() > 0, 'Deve retornar ao menos uma sugestao');
    }

    @IsTest
    static void retornaVazioSemSaldo() {
        User u = criarColaborador();

        FeriasSugerirDatas.Request req = new FeriasSugerirDatas.Request();
        req.userId = u.Id;
        req.dataInicioPretendida = Date.today().addDays(45);
        req.diasSolicitados = 5;

        Test.startTest();
        List<FeriasSugerirDatas.Result> res = FeriasSugerirDatas.suggest(
            new List<FeriasSugerirDatas.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals('', res[0].datasSugeridas);
    }

    @IsTest
    static void retornaVazioRequestNulo() {
        Test.startTest();
        List<FeriasSugerirDatas.Result> res = FeriasSugerirDatas.suggest(null);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }
}
