public without sharing class SaldoFeriasController {
    @AuraEnabled(cacheable=true)
    public static Saldo_Ferias__c getSaldoVigente() {
        Id userId = UserInfo.getUserId();
        List<Saldo_Ferias__c> saldos = [
            SELECT Id,
                   Name,
                   Regime_Contratacao__c,
                   Periodo_Aquisitivo_Inicio__c,
                   Periodo_Aquisitivo_Fim__c,
                   Periodo_Concessivo_Fim__c,
                   Dias_Direito__c,
                   Dias_Tirados__c,
                   Dias_Disponiveis__c,
                   Dias_Abono_Vendidos__c,
                   Status__c
            FROM Saldo_Ferias__c
            WHERE Colaborador__c = :userId
              AND Status__c = 'Vigente'
            ORDER BY Periodo_Aquisitivo_Inicio__c DESC
            LIMIT 1
        ];
        return saldos.isEmpty() ? null : saldos[0];
    }
}
