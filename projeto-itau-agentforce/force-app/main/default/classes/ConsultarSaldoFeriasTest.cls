@IsTest
private class ConsultarSaldoFeriasTest {

    @IsTest
    static void testRequestNullRetornaUmResultado() {
        User u = criarUsuarioTeste();

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(null);
        }
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Deveria retornar exatamente 1 resultado mesmo com lista nula.');
        System.assertEquals(true, res[0].success, 'Consulta tecnica deveria rodar com sucesso.');
        System.assertEquals(false, res[0].temSaldoSuficiente, 'Usuario novo sem saldo cadastrado.');
        System.assert(String.isNotBlank(res[0].message), 'Mensagem amigavel obrigatoria.');
    }

    @IsTest
    static void testSemSaldoVigente() {
        User u = criarUsuarioTeste();

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ new ConsultarSaldoFerias.Request() });
        }
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(true, res[0].success);
        System.assertEquals(false, res[0].temSaldoSuficiente);
        System.assert(
            res[0].message.containsIgnoreCase('vigente') || res[0].message.containsIgnoreCase('rh'),
            'Mensagem deve orientar a procurar o RH quando nao ha saldo. Atual: ' + res[0].message
        );
    }

    @IsTest
    static void testSaldoZeradoBloqueiaHandoff() {
        User u = criarUsuarioTeste();
        Saldo_Ferias__c s = criarSaldo(u.Id, 'CLT', 30, 30, 'Vigente');
        System.runAs(u) {
            insert s;
        }

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ new ConsultarSaldoFerias.Request() });
        }
        Test.stopTest();

        System.assertEquals(true, res[0].success);
        System.assertEquals(false, res[0].temSaldoSuficiente, 'Sem dias disponiveis nao deve liberar handoff.');
        System.assertEquals(0, res[0].diasDisponiveis);
        System.assertEquals(30, res[0].diasDireito);
        System.assertEquals(30, res[0].diasTirados);
        System.assertEquals('CLT', res[0].regimeContratacao);
        System.assert(res[0].message.contains('0'), 'Mensagem deve indicar 0 dias disponiveis. Atual: ' + res[0].message);
    }

    @IsTest
    static void testSaldoMenorQue5BloqueiaHandoff() {
        User u = criarUsuarioTeste();
        Saldo_Ferias__c s = criarSaldo(u.Id, 'CLT', 30, 27, 'Vigente');
        System.runAs(u) {
            insert s;
        }

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ new ConsultarSaldoFerias.Request() });
        }
        Test.stopTest();

        System.assertEquals(true, res[0].success);
        System.assertEquals(false, res[0].temSaldoSuficiente, '3 dias < minimo de 5 nao deve liberar handoff.');
        System.assertEquals(3, res[0].diasDisponiveis);
        System.assert(
            res[0].message.containsIgnoreCase('5 dias') || res[0].message.containsIgnoreCase('CLT'),
            'Mensagem deve mencionar a regra dos 5 dias. Atual: ' + res[0].message
        );
    }

    @IsTest
    static void testSaldoSuficienteLiberaConfirmacao() {
        User u = criarUsuarioTeste();
        Saldo_Ferias__c s = criarSaldo(u.Id, 'CLT', 30, 0, 'Vigente');
        System.runAs(u) {
            insert s;
        }

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ new ConsultarSaldoFerias.Request() });
        }
        Test.stopTest();

        System.assertEquals(true, res[0].success);
        System.assertEquals(true, res[0].temSaldoSuficiente, '30 dias disponiveis devem liberar handoff.');
        System.assertEquals(30, res[0].diasDisponiveis);
        System.assertEquals('CLT', res[0].regimeContratacao);
        System.assertNotEquals(null, res[0].periodoConcessivoFim, 'Concessivo deve ser preenchido (DD/MM/YYYY).');
        System.assert(
            res[0].message.containsIgnoreCase('sim') || res[0].message.containsIgnoreCase('liberar'),
            'Mensagem deve pedir confirmacao explicita. Atual: ' + res[0].message
        );
    }

    @IsTest
    static void testSaldoVencidoNaoConta() {
        User u = criarUsuarioTeste();
        Saldo_Ferias__c s = criarSaldo(u.Id, 'CLT', 30, 0, 'Vencido');
        System.runAs(u) {
            insert s;
        }

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(new List<ConsultarSaldoFerias.Request>{ new ConsultarSaldoFerias.Request() });
        }
        Test.stopTest();

        System.assertEquals(true, res[0].success);
        System.assertEquals(false, res[0].temSaldoSuficiente, 'Saldo nao Vigente deve ser ignorado.');
        System.assert(
            res[0].message.containsIgnoreCase('vigente') || res[0].message.containsIgnoreCase('rh'),
            'Mensagem deve tratar como sem saldo vigente. Atual: ' + res[0].message
        );
    }

    @IsTest
    static void testRetornaUmResultadoPorRequest() {
        User u = criarUsuarioTeste();

        Test.startTest();
        List<ConsultarSaldoFerias.Result> res;
        System.runAs(u) {
            res = ConsultarSaldoFerias.consultar(
                new List<ConsultarSaldoFerias.Request>{
                    new ConsultarSaldoFerias.Request(),
                    new ConsultarSaldoFerias.Request(),
                    new ConsultarSaldoFerias.Request()
                }
            );
        }
        Test.stopTest();

        System.assertEquals(3, res.size(), 'Deveria retornar 1 resultado por request (bulk-safe).');
    }

    private static User criarUsuarioTeste() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String suf = String.valueOf(System.currentTimeMillis()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User u = new User(
            FirstName = 'TST',
            LastName = 'SaldoFer',
            Email = 'tstsaldo' + suf + '@example.com.invalid',
            Username = 'tstsaldo' + suf + '@example.com.invalid.sfdc',
            Alias = ('t' + suf).left(8),
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static Saldo_Ferias__c criarSaldo(Id colaboradorId, String regime, Integer diasDireitoEsperado, Integer diasTirados, String status) {
        Integer faltas = (regime == 'CLT' && diasDireitoEsperado == 30) ? 0 : 0;
        Date hoje = Date.today();
        return new Saldo_Ferias__c(
            Colaborador__c = colaboradorId,
            Regime_Contratacao__c = regime,
            Periodo_Aquisitivo_Inicio__c = hoje.addYears(-1),
            Faltas_Injustificadas__c = faltas,
            Dias_Tirados__c = diasTirados,
            Dias_Abono_Vendidos__c = 0,
            Status__c = status
        );
    }
}
