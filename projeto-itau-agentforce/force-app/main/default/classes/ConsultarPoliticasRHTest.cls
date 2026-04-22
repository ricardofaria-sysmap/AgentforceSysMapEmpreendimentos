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
    static void testQueryExecuta() {
        ConsultarPoliticasRH.Request req = new ConsultarPoliticasRH.Request();
        req.query = 'ferias';

        Test.startTest();
        List<ConsultarPoliticasRH.Result> res = ConsultarPoliticasRH.consultar(new List<ConsultarPoliticasRH.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertNotEquals(null, res[0].articles);
        System.assertEquals(res[0].articles.size(), res[0].totalEncontrados);
    }
}
