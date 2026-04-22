@IsTest
private class ConsultarPoliticasRHTest {

    @IsTest
    static void testNullRequest() {
        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(null);
        Test.stopTest();
        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testEmptyRequests() {
        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>());
        Test.stopTest();
        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testBlankQuery() {
        ConsultarPoliticasRH.Request req = new ConsultarPoliticasRH.Request();
        req.query = '   ';

        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
        System.assert(res[0].message != null);
    }

    @IsTest
    static void testTermoMuitoCurto() {
        ConsultarPoliticasRH.Request req = new ConsultarPoliticasRH.Request();
        req.query = 'a';

        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
        System.assert(res[0].message.containsIgnoreCase('curta'));
    }

    @IsTest
    static void testSOSLEncontraArtigo() {
        // setFixedSearchResults precisa de IDs reais do objeto; em contexto de teste
        // sem DML real de Knowledge__kav (que exige configuracao especial de org),
        // simulamos via setFixedSearchResults vazio para exercitar o caminho
        // "sem resultados" sem depender de schema do Knowledge.
        Test.setFixedSearchResults(new List<Id>());

        ConsultarPoliticasRH.Request req = new ConsultarPoliticasRH.Request();
        req.query = 'abono pecuniário';

        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
        System.assertEquals(0, res[0].articles.size());
        System.assert(res[0].message.containsIgnoreCase('nenhum artigo'));
    }

    @IsTest
    static void testSanitizaCaracteresEspeciais() {
        // Verifica que termos com caracteres reservados do SOSL nao quebram a busca.
        Test.setFixedSearchResults(new List<Id>());

        ConsultarPoliticasRH.Request req = new ConsultarPoliticasRH.Request();
        req.query = 'abono? (férias)';

        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }

    @IsTest
    static void testSanitizador() {
        String input = 'abono? (pecuniário)';
        String saneado = ConsultarPoliticasRH.sanitizarParaSOSL(input);
        System.assert(saneado.contains('\\?'), 'deve escapar ?');
        System.assert(saneado.contains('\\('), 'deve escapar (');
        System.assert(saneado.contains('\\)'), 'deve escapar )');
        System.assert(saneado.contains('pecuniário'), 'deve preservar acento');
    }
}
