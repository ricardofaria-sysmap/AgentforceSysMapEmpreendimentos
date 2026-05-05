public with sharing class ConsultarSaldoFerias {

    private static final Integer MIN_DIAS_PARA_AGENDAR = 5;

    @InvocableMethod(
        label='Consultar Saldo de Ferias do Colaborador'
        description='Consulta o saldo de ferias vigente do usuario logado. Retorna dias disponiveis, regime e uma mensagem pre-formatada que o agente deve transmitir literalmente ao colaborador. Use antes de pedir confirmacao para handoff: se temSaldoSuficiente=false, NAO chame iniciar_handoff_agendamento.'
        callout=false
    )
    public static List<Result> consultar(List<Request> requests) {
        List<Result> out = new List<Result>();
        Integer turns = (requests == null || requests.isEmpty()) ? 1 : requests.size();
        Id userId = UserInfo.getUserId();

        for (Integer i = 0; i < turns; i++) {
            Result r = new Result();
            r.success = false;
            r.temSaldoSuficiente = false;
            r.diasDisponiveis = 0;
            r.diasDireito = 0;
            r.diasTirados = 0;

            try {
                List<Saldo_Ferias__c> saldos = [
                    SELECT
                        Id,
                        Status__c,
                        Regime_Contratacao__c,
                        Dias_Direito__c,
                        Dias_Tirados__c,
                        Dias_Disponiveis__c,
                        Periodo_Concessivo_Fim__c
                    FROM Saldo_Ferias__c
                    WHERE Colaborador__c = :userId
                      AND Status__c = 'Vigente'
                    ORDER BY Periodo_Concessivo_Fim__c ASC NULLS LAST
                    LIMIT 1
                ];

                r.success = true;

                if (saldos.isEmpty()) {
                    r.message = 'Voce nao possui um saldo de ferias vigente cadastrado. Procure o RH pelo canal oficial para regularizar antes de tentar agendar.';
                    out.add(r);
                    continue;
                }

                Saldo_Ferias__c s = saldos[0];
                r.diasDireito = toInt(s.Dias_Direito__c);
                r.diasTirados = toInt(s.Dias_Tirados__c);
                r.diasDisponiveis = toInt(s.Dias_Disponiveis__c);
                r.regimeContratacao = s.Regime_Contratacao__c;
                r.periodoConcessivoFim = formatarData(s.Periodo_Concessivo_Fim__c);

                if (r.diasDisponiveis < MIN_DIAS_PARA_AGENDAR) {
                    r.temSaldoSuficiente = false;
                    if (r.diasDisponiveis <= 0) {
                        r.message = 'Voce nao tem dias de ferias disponiveis no momento (saldo atual: 0 de '
                            + r.diasDireito + ' dias). Nao consigo liberar o calendario. Procure o RH para entender as proximas opcoes.';
                    } else {
                        r.message = 'Voce tem apenas ' + r.diasDisponiveis + ' dia(s) disponivel(is). Pela CLT '
                            + 'sao necessarios ao menos ' + MIN_DIAS_PARA_AGENDAR + ' dias corridos para iniciar um periodo de ferias, '
                            + 'entao nao consigo liberar o calendario agora. Procure o RH para discutir alternativas.';
                    }
                } else {
                    r.temSaldoSuficiente = true;
                    String regimeTxt = String.isBlank(r.regimeContratacao) ? '' : ' (regime ' + r.regimeContratacao + ')';
                    String concessivoTxt = String.isBlank(r.periodoConcessivoFim) ? '' : ', concessivo ate ' + r.periodoConcessivoFim;
                    r.message = 'Voce tem ' + r.diasDisponiveis + ' dia(s) disponivel(is)' + regimeTxt + concessivoTxt
                        + '. Posso liberar o calendario para voce escolher o periodo? Responda sim para confirmar.';
                }
            } catch (Exception e) {
                r.success = false;
                r.message = 'Nao consegui consultar seu saldo de ferias agora: ' + e.getMessage()
                    + '. Tente novamente em instantes ou contate o RH.';
            }

            out.add(r);
        }

        return out;
    }

    private static Integer toInt(Decimal d) {
        return d == null ? 0 : d.intValue();
    }

    private static String formatarData(Date d) {
        if (d == null) {
            return null;
        }
        return String.valueOf(d.day()).leftPad(2, '0') + '/'
            + String.valueOf(d.month()).leftPad(2, '0') + '/'
            + String.valueOf(d.year());
    }

    public class Request {
        @InvocableVariable(
            label='Token opcional'
            description='Nao utilizado. Mantido para o agente poder enviar a request mesmo sem inputs.'
            required=false
        )
        public String token;
    }

    public class Result {
        @InvocableVariable(label='Sucesso da consulta (tecnico)')
        public Boolean success;

        @InvocableVariable(label='Tem saldo suficiente para agendar (>= 5 dias e vigente)')
        public Boolean temSaldoSuficiente;

        @InvocableVariable(label='Dias disponiveis')
        public Integer diasDisponiveis;

        @InvocableVariable(label='Dias de direito (total do periodo)')
        public Integer diasDireito;

        @InvocableVariable(label='Dias ja tirados')
        public Integer diasTirados;

        @InvocableVariable(label='Regime de contratacao (CLT/PJ)')
        public String regimeContratacao;

        @InvocableVariable(label='Fim do periodo concessivo (DD/MM/YYYY)')
        public String periodoConcessivoFim;

        @InvocableVariable(label='Mensagem pronta para o agente transmitir')
        public String message;
    }
}
