@IsTest
private class FeriasDateRulesServiceTest {

    @IsTest
    static void testContextoComSaldo() {
        User u = new User(
            FirstName = 'Fer',
            LastName = 'Rules',
            Email = 'fer.rules@itau.com.invalid',
            Username = 'fer.rules@itau.com.invalid.' + System.currentTimeMillis(),
            Alias = 'ferule',
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert u;

        Saldo_Ferias__c s;
        System.runAs(u) {
            s = new Saldo_Ferias__c(
                Colaborador__c = u.Id,
                Regime_Contratacao__c = 'CLT',
                Periodo_Aquisitivo_Inicio__c = Date.today().addYears(-1),
                Dias_Tirados__c = 0,
                Faltas_Injustificadas__c = 0,
                Dias_Abono_Vendidos__c = 0,
                Status__c = 'Vigente'
            );
            insert s;
        }

        FeriasDateRulesService.CalendarContext ctx;
        System.runAs(u) {
            ctx = FeriasDateRulesService.getCalendarContext(s.Id);
        }

        System.assertNotEquals(null, ctx, 'Contexto deve existir');
        System.assertEquals(Date.today().addDays(30), ctx.minStartDate);
        System.assertNotEquals(null, ctx.blockedStartIsoDates);
    }

    @IsTest
    static void testSaldoInvalidoLanca() {
        Boolean threw = false;
        try {
            FeriasDateRulesService.getCalendarContext(UserInfo.getUserId());
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Id que nao e saldo deve falhar');
    }
}
