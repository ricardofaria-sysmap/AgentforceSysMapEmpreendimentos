@IsTest
private class FeriasEmailSenderTest {

    @IsTest
    static void testEmptyInput() {
        Test.startTest();
        FeriasEmailSender.send(null);
        FeriasEmailSender.send(new List<FeriasEmailSender.Request>());
        Test.stopTest();
        System.assert(true, 'Empty input nao deve lancar excecao.');
    }

    @IsTest
    static void testRequestWithoutCaseId() {
        FeriasEmailSender.Request req = new FeriasEmailSender.Request();
        req.tipo = 'APROVADO';

        Test.startTest();
        FeriasEmailSender.send(new List<FeriasEmailSender.Request>{ req });
        Test.stopTest();
        System.assert(true, 'Request sem caseId deve ser tolerado.');
    }

    @IsTest
    static void testInvalidCaseId() {
        FeriasEmailSender.Request req = new FeriasEmailSender.Request();
        req.caseId = '500000000000000AAA';
        req.tipo = 'LEMBRETE';

        Test.startTest();
        FeriasEmailSender.send(new List<FeriasEmailSender.Request>{ req });
        Test.stopTest();
        System.assert(true, 'CaseId inexistente nao deve lancar excecao.');
    }
}
