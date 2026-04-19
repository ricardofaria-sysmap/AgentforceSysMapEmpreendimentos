@IsTest
private class FeriasApprovalSubmitterTest {

    @IsTest
    static void testEmptyInput() {
        Test.startTest();
        List<FeriasApprovalSubmitter.Result> r1 = FeriasApprovalSubmitter.submit(null);
        List<FeriasApprovalSubmitter.Result> r2 = FeriasApprovalSubmitter.submit(new List<FeriasApprovalSubmitter.Request>());
        Test.stopTest();
        System.assertEquals(0, r1.size());
        System.assertEquals(0, r2.size());
    }

    @IsTest
    static void testMissingCaseId() {
        FeriasApprovalSubmitter.Request req = new FeriasApprovalSubmitter.Request();

        Test.startTest();
        List<FeriasApprovalSubmitter.Result> res = FeriasApprovalSubmitter.submit(new List<FeriasApprovalSubmitter.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
        System.assert(res[0].errorMessage != null);
    }

    @IsTest
    static void testInvalidCaseId() {
        FeriasApprovalSubmitter.Request req = new FeriasApprovalSubmitter.Request();
        req.caseId = '500000000000000AAA';

        Test.startTest();
        List<FeriasApprovalSubmitter.Result> res = FeriasApprovalSubmitter.submit(new List<FeriasApprovalSubmitter.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].success);
    }
}
