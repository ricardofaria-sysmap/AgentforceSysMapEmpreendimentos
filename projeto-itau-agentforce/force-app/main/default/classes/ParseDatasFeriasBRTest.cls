@IsTest
private class ParseDatasFeriasBRTest {

    @IsTest
    static void testBr_invertedJune_sameYear() {
        ParseDatasFeriasBR.Request req = new ParseDatasFeriasBR.Request();
        req.textoDataInicio = '30/06/2026';
        req.textoDataRetorno = '04/06/2026';

        Test.startTest();
        List<ParseDatasFeriasBR.Result> res = ParseDatasFeriasBR.parse(new List<ParseDatasFeriasBR.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(true, res[0].success, 'Parse BR 30/06 e 04/06 deve ter sucesso: ' + res[0].message);
        System.assertEquals('2026-06-30', res[0].dataInicioIso);
        System.assertEquals('2026-06-04', res[0].dataRetornoIso);
    }

    @IsTest
    static void testIso_passThrough() {
        ParseDatasFeriasBR.Request req = new ParseDatasFeriasBR.Request();
        req.textoDataInicio = '2026-06-30';
        req.textoDataRetorno = '2026-06-04';

        List<ParseDatasFeriasBR.Result> res = ParseDatasFeriasBR.parse(new List<ParseDatasFeriasBR.Request>{ req });

        System.assertEquals(true, res[0].success);
        System.assertEquals('2026-06-30', res[0].dataInicioIso);
        System.assertEquals('2026-06-04', res[0].dataRetornoIso);
    }

    @IsTest
    static void testBlank_fails() {
        ParseDatasFeriasBR.Request req = new ParseDatasFeriasBR.Request();
        req.textoDataInicio = '';
        req.textoDataRetorno = '01/07/2026';

        List<ParseDatasFeriasBR.Result> res = ParseDatasFeriasBR.parse(new List<ParseDatasFeriasBR.Request>{ req });

        System.assertEquals(false, res[0].success);
    }

    @IsTest
    static void testInvalidBr_fails() {
        ParseDatasFeriasBR.Request req = new ParseDatasFeriasBR.Request();
        req.textoDataInicio = '32/06/2026';
        req.textoDataRetorno = '01/07/2026';

        List<ParseDatasFeriasBR.Result> res = ParseDatasFeriasBR.parse(new List<ParseDatasFeriasBR.Request>{ req });

        System.assertEquals(false, res[0].success);
    }

    @IsTest
    static void testParseFlexible_brSingleDigit() {
        Date d = ParseDatasFeriasBR.parseFlexible('8/6/2026');
        System.assertEquals(Date.newInstance(2026, 6, 8), d);
    }

    @IsTest
    static void testNullRequest() {
        List<ParseDatasFeriasBR.Result> res = ParseDatasFeriasBR.parse(null);
        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }
}
