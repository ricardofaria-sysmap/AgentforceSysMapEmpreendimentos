public without sharing class FeriasSugerirDatas {

    private static final Integer MAX_SUGESTOES = 5;
    private static final Integer JANELA_DIAS_BUSCA = 180;

    @InvocableMethod(label='Sugerir Datas de Ferias' description='Retorna ate 5 datas de inicio validas (CLT + saldo + concessivo) a partir de uma data pretendida.')
    public static List<Result> suggest(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (Request req : requests) {
            Result res = new Result();
            res.datasSugeridas = '';
            try {
                res.datasSugeridas = buildSuggestions(req);
            } catch (Exception e) {
                res.datasSugeridas = '';
            }
            results.add(res);
        }
        return results;
    }

    private static String buildSuggestions(Request req) {
        Id callerUserId = UserInfo.getUserId();
        if (req == null || callerUserId == null) {
            return '';
        }
        Integer dias = req.diasSolicitados == null ? 5 : Math.max(5, req.diasSolicitados.intValue());

        List<Saldo_Ferias__c> saldos = [
            SELECT Id, Periodo_Concessivo_Fim__c, Dias_Disponiveis__c, Dias_Direito__c
            FROM Saldo_Ferias__c
            WHERE Colaborador__c = :callerUserId
              AND Status__c = 'Vigente'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (saldos.isEmpty()) {
            return '';
        }
        Saldo_Ferias__c saldo = saldos[0];
        Decimal disp = saldo.Dias_Disponiveis__c == null ? 0 : saldo.Dias_Disponiveis__c;
        if (disp.intValue() < dias) {
            dias = disp.intValue();
        }
        if (dias < 5) {
            return '';
        }

        Date hoje = Date.today();
        Date pretendida = req.dataInicioPretendida;
        Date minStart = hoje.addDays(30);
        Date base = (pretendida != null && pretendida > minStart) ? pretendida : minStart;

        Date concessivoEnd = saldo.Periodo_Concessivo_Fim__c;
        Date maxStart = (concessivoEnd != null) ? concessivoEnd.addDays(-(dias - 1)) : base.addDays(JANELA_DIAS_BUSCA);
        if (maxStart < base) {
            return '';
        }

        Date queryEnd = maxStart.addDays(2);
        Set<Date> holidays = new Set<Date>();
        for (Feriado__c f : [
            SELECT Data__c
            FROM Feriado__c
            WHERE Data__c >= :base AND Data__c <= :queryEnd
        ]) {
            if (f.Data__c != null) {
                holidays.add(f.Data__c);
            }
        }

        List<String> sugestoes = new List<String>();
        Date cursor = base;
        while (cursor <= maxStart && sugestoes.size() < MAX_SUGESTOES) {
            if (isValidStart(cursor, holidays)) {
                sugestoes.add(formatBr(cursor) + ' a ' + formatBr(cursor.addDays(dias - 1)));
            }
            cursor = cursor.addDays(1);
        }
        if (sugestoes.isEmpty()) {
            return '';
        }
        return String.join(sugestoes, '; ');
    }

    private static Boolean isValidStart(Date d, Set<Date> holidays) {
        Integer wd = FeriasDateRulesService.salesforceWeekday(d);
        if (wd == 1 || wd == 5 || wd == 6 || wd == 7) {
            return false;
        }
        if (holidays.contains(d)) {
            return false;
        }
        if (holidays.contains(d.addDays(1)) || holidays.contains(d.addDays(2))) {
            return false;
        }
        return true;
    }

    private static String formatBr(Date d) {
        Datetime dt = Datetime.newInstanceGmt(d.year(), d.month(), d.day());
        return dt.format('dd/MM/yyyy');
    }

    public class Request {
        @InvocableVariable(label='User Id' required=true)
        public Id userId;

        @InvocableVariable(label='Data Inicio Pretendida')
        public Date dataInicioPretendida;

        @InvocableVariable(label='Dias Solicitados')
        public Decimal diasSolicitados;
    }

    public class Result {
        @InvocableVariable(label='Datas Sugeridas')
        public String datasSugeridas;
    }
}
