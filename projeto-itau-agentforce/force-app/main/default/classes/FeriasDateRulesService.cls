public without sharing class FeriasDateRulesService {
    /**
     * Salesforce formula WEEKDAY: Sunday = 1 ... Saturday = 7.
     */
    public static Integer salesforceWeekday(Date d) {
        Date refSunday = Date.newInstance(1900, 1, 7);
        Integer days = refSunday.daysBetween(d);
        Integer mod = Math.mod(days, 7);
        return mod + 1;
    }

    public class CalendarContext {
        @AuraEnabled
        public Date minStartDate;
        @AuraEnabled
        public Date maxStartDate;
        @AuraEnabled
        public Date concessivoEnd;
        @AuraEnabled
        public Decimal diasDisponiveis;
        @AuraEnabled
        public List<String> blockedStartIsoDates;
    }

    @AuraEnabled(cacheable = true)
    public static CalendarContext getCalendarContext(Id saldoFeriasId) {
        Id currentUserId = UserInfo.getUserId();
        List<Saldo_Ferias__c> saldos;
        if (saldoFeriasId == null) {
            saldos = [
                SELECT Id, Periodo_Concessivo_Fim__c, Dias_Disponiveis__c
                FROM Saldo_Ferias__c
                WHERE Colaborador__c = :currentUserId
                  AND Status__c = 'Vigente'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } else {
            saldos = [
                SELECT Id, Periodo_Concessivo_Fim__c, Dias_Disponiveis__c
                FROM Saldo_Ferias__c
                WHERE Id = :saldoFeriasId
                  AND Colaborador__c = :currentUserId
                LIMIT 1
            ];
        }
        if (saldos.isEmpty()) {
            throw new AuraHandledException('Saldo de ferias nao encontrado ou sem permissao.');
        }

        Saldo_Ferias__c saldo = saldos[0];
        Date concessivoEnd = saldo.Periodo_Concessivo_Fim__c;
        Decimal dispDec = saldo.Dias_Disponiveis__c == null ? 0 : saldo.Dias_Disponiveis__c;
        Integer diasInt = dispDec.intValue();
        if (diasInt < 1) {
            diasInt = 1;
        }

        Date minStart = Date.today().addDays(30);
        Integer maxOffset = Math.max(4, diasInt - 1);
        Date maxStart = concessivoEnd.addDays(-maxOffset);

        CalendarContext ctx = new CalendarContext();
        ctx.minStartDate = minStart;
        ctx.maxStartDate = maxStart;
        ctx.concessivoEnd = concessivoEnd;
        ctx.diasDisponiveis = dispDec;
        ctx.blockedStartIsoDates = new List<String>();

        if (maxStart < minStart) {
            return ctx;
        }

        Date queryEnd = maxStart.addDays(2);
        Set<Date> holidayDates = new Set<Date>();
        for (Feriado__c f : [
            SELECT Data__c
            FROM Feriado__c
            WHERE Data__c >= :minStart AND Data__c <= :queryEnd
            ORDER BY Data__c
        ]) {
            if (f.Data__c != null) {
                holidayDates.add(f.Data__c);
            }
        }

        for (Date d = minStart; d <= maxStart; d = d.addDays(1)) {
            if (isBlockedStartDate(d, holidayDates)) {
                ctx.blockedStartIsoDates.add(toIsoDate(d));
            }
        }

        return ctx;
    }

    private static Boolean isBlockedStartDate(Date d, Set<Date> holidayDates) {
        Integer wd = salesforceWeekday(d);
        if (wd == 1 || wd == 6 || wd == 7) {
            return true;
        }
        if (holidayDates.contains(d)) {
            return true;
        }
        Date d1 = d.addDays(1);
        Date d2 = d.addDays(2);
        if (holidayDates.contains(d1) || holidayDates.contains(d2)) {
            return true;
        }
        return false;
    }

    private static String toIsoDate(Date d) {
        Datetime dt = Datetime.newInstanceGmt(d.year(), d.month(), d.day());
        return dt.format('yyyy-MM-dd');
    }
}
