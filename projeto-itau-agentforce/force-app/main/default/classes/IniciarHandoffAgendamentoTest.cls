@IsTest
private class IniciarHandoffAgendamentoTest {

    @IsTest
    static void publicaEventoComMensagemPadraoQuandoRequestSemMensagem() {
        Test.startTest();
        List<IniciarHandoffAgendamento.Result> res = IniciarHandoffAgendamento.iniciar(
            new List<IniciarHandoffAgendamento.Request>{ new IniciarHandoffAgendamento.Request() }
        );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Deveria retornar exatamente 1 resultado.');
        System.assertEquals(true, res.get(0).success, 'Publicacao deveria ter sucesso em testes.');
        System.assertNotEquals(null, res.get(0).userId, 'userId deveria ser preenchido.');
        System.assert(res.get(0).message.contains('Calendario'), 'Mensagem deveria mencionar calendario.');
    }

    @IsTest
    static void aceitaListaNullaERetornaResultado() {
        Test.startTest();
        List<IniciarHandoffAgendamento.Result> res = IniciarHandoffAgendamento.iniciar(null);
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(true, res.get(0).success);
    }

    @IsTest
    static void usaMensagemCustomQuandoFornecida() {
        IniciarHandoffAgendamento.Request req = new IniciarHandoffAgendamento.Request();
        req.mensagem = 'Mensagem customizada do agente';
        req.sessionId = 'SESSAO_X';

        Test.startTest();
        List<IniciarHandoffAgendamento.Result> res = IniciarHandoffAgendamento.iniciar(
            new List<IniciarHandoffAgendamento.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, res.get(0).success, 'Publicacao deveria ter sucesso.');
    }

    @IsTest
    static void truncaMensagemMaiorQue255Chars() {
        IniciarHandoffAgendamento.Request req = new IniciarHandoffAgendamento.Request();
        req.mensagem = 'X'.repeat(400);

        Test.startTest();
        List<IniciarHandoffAgendamento.Result> res = IniciarHandoffAgendamento.iniciar(
            new List<IniciarHandoffAgendamento.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, res.get(0).success, 'Mesmo com mensagem longa deve publicar (truncada).');
    }
}
