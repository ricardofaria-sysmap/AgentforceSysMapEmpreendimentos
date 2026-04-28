public without sharing class ConsultarSaldoFerias {

    @InvocableMethod(
        label='Consultar Saldo de Ferias'
        description='Retorna o saldo vigente de ferias do colaborador informado. Se userId vier vazio usa o usuario logado. Retorna escalares para o Agent compor a resposta.'
    )
    public static List<Result> consultar(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return new List<Result>{ build(null, 'userId obrigatorio.') };
        }

        for (Request req : requests) {
            Id userId = UserInfo.getUserId();

            List<Saldo_Ferias__c> saldos = [
                SELECT Id, Name, Regime_Contratacao__c,
                       Periodo_Aquisitivo_Inicio__c, Periodo_Aquisitivo_Fim__c,
                       Periodo_Concessivo_Fim__c,
                       Dias_Direito__c, Dias_Tirados__c, Dias_Disponiveis__c,
                       Dias_Abono_Vendidos__c, Faltas_Injustificadas__c,
                       Status__c
                FROM Saldo_Ferias__c
                WHERE Colaborador__c = :userId
                  AND Status__c = 'Vigente'
                ORDER BY Periodo_Aquisitivo_Inicio__c DESC
                LIMIT 1
            ];

            if (saldos.isEmpty()) {
                results.add(build(null, 'Nenhum saldo vigente encontrado para o colaborador. Oriente o usuario a procurar o RH.'));
                continue;
            }

            results.add(build(saldos[0], null));
        }
        return results;
    }

    private static Result build(Saldo_Ferias__c s, String err) {
        Result r = new Result();
        if (s == null) {
            r.success = false;
            r.message = err;
            return r;
        }
        r.success = true;
        r.saldoId = s.Id;
        r.saldoName = s.Name;
        r.regime = s.Regime_Contratacao__c;
        r.diasDireito = s.Dias_Direito__c;
        r.diasTirados = s.Dias_Tirados__c;
        r.diasDisponiveis = s.Dias_Disponiveis__c;
        r.diasAbonoVendidos = s.Dias_Abono_Vendidos__c;
        r.faltasInjustificadas = s.Faltas_Injustificadas__c;
        r.periodoAquisitivoInicio = s.Periodo_Aquisitivo_Inicio__c;
        r.periodoAquisitivoFim = s.Periodo_Aquisitivo_Fim__c;
        r.periodoConcessivoFim = s.Periodo_Concessivo_Fim__c;
        r.status = s.Status__c;
        return r;
    }

    public class Request {
        @InvocableVariable(label='User Id (opcional - usa logado se vazio)')
        public String userId;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem de erro (se houver)')
        public String message;

        @InvocableVariable(label='Saldo Id')
        public Id saldoId;

        @InvocableVariable(label='Saldo Name (codigo)')
        public String saldoName;

        @InvocableVariable(label='Regime (CLT/PJ)')
        public String regime;

        @InvocableVariable(label='Dias de direito')
        public Decimal diasDireito;

        @InvocableVariable(label='Dias tirados')
        public Decimal diasTirados;

        @InvocableVariable(label='Dias disponiveis')
        public Decimal diasDisponiveis;

        @InvocableVariable(label='Dias de abono ja vendidos')
        public Decimal diasAbonoVendidos;

        @InvocableVariable(label='Faltas injustificadas')
        public Decimal faltasInjustificadas;

        @InvocableVariable(label='Periodo aquisitivo inicio')
        public Date periodoAquisitivoInicio;

        @InvocableVariable(label='Periodo aquisitivo fim')
        public Date periodoAquisitivoFim;

        @InvocableVariable(label='Periodo concessivo fim (limite legal)')
        public Date periodoConcessivoFim;

        @InvocableVariable(label='Status')
        public String status;
    }
}
