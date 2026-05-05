public without sharing class SaldoFeriasController {
    public class SaldoFeriasCardData {
        @AuraEnabled public Saldo_Ferias__c saldo;
        @AuraEnabled public List<Case> solicitacoes;

        public SaldoFeriasCardData(Saldo_Ferias__c saldo, List<Case> solicitacoes) {
            this.saldo = saldo;
            this.solicitacoes = solicitacoes;
        }
    }

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

    @AuraEnabled(cacheable=true)
    public static SaldoFeriasCardData getSaldoCardData() {
        Id userId = UserInfo.getUserId();
        Saldo_Ferias__c saldo = getSaldoVigente();
        List<Case> solicitacoes = [
            SELECT Id,
                   CaseNumber,
                   Aprovacao_Gestor__c,
                   Status,
                   Data_Inicio_Ferias__c,
                   Data_Retorno_Ferias__c,
                   CreatedDate
            FROM Case
            WHERE RecordType.DeveloperName = 'Pedido_Ferias'
              AND IsDeleted = false
              AND (OwnerId = :userId OR CreatedById = :userId)
            ORDER BY CreatedDate DESC
            LIMIT 3
        ];

        return new SaldoFeriasCardData(saldo, solicitacoes);
    }
}
