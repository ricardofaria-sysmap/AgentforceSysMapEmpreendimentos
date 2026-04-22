// Cria/atualiza um Saldo_Ferias__c Vigente (CLT, 30 dias) para o usuario logado.
// Uso rapido para testar o Agent_Itau_RH_Employee sem precisar de login-as.
// Idempotente: se ja existe um Saldo Vigente para o user, apenas atualiza.

Id userId = UserInfo.getUserId();
String userName = UserInfo.getName();
String userEmail = UserInfo.getUserEmail();

System.debug('Criando Saldo_Ferias__c para: ' + userName + ' (' + userEmail + ') [' + userId + ']');

// Aquisitivo_Fim e Concessivo_Fim sao formulas calculadas a partir de Aquisitivo_Inicio.
// Usamos Aquisitivo_Inicio = hoje - 18 meses para gerar Aquisitivo_Fim = hoje - 6m e Concessivo_Fim = hoje + 6m.
Date aquisitivoInicio = Date.today().addMonths(-18);

List<Saldo_Ferias__c> existentes = [
    SELECT Id FROM Saldo_Ferias__c
    WHERE Colaborador__c = :userId AND Status__c = 'Vigente'
    LIMIT 1
];

Saldo_Ferias__c s;
if (!existentes.isEmpty()) {
    s = existentes[0];
    System.debug('Atualizando Saldo existente: ' + s.Id);
} else {
    s = new Saldo_Ferias__c();
    s.Colaborador__c = userId;
    System.debug('Criando novo Saldo');
}

// Dias_Direito__c e formula (CLT + 0 faltas = 30 dias). Dias_Disponiveis__c tambem e formula.
s.Regime_Contratacao__c        = 'CLT';
s.Status__c                    = 'Vigente';
s.Periodo_Aquisitivo_Inicio__c = aquisitivoInicio;
s.Dias_Tirados__c              = 0;
s.Dias_Abono_Vendidos__c       = 0;
s.Faltas_Injustificadas__c     = 0;

upsert s;

Saldo_Ferias__c check = [
    SELECT Id, Name, Colaborador__r.Name, Regime_Contratacao__c, Status__c,
           Dias_Direito__c, Dias_Tirados__c, Dias_Abono_Vendidos__c, Dias_Disponiveis__c,
           Periodo_Aquisitivo_Inicio__c, Periodo_Aquisitivo_Fim__c, Periodo_Concessivo_Fim__c
    FROM Saldo_Ferias__c WHERE Id = :s.Id
];

System.debug('=== SALDO CRIADO/ATUALIZADO ===');
System.debug('Id: ' + check.Id);
System.debug('Name: ' + check.Name);
System.debug('Colaborador: ' + check.Colaborador__r.Name);
System.debug('Regime: ' + check.Regime_Contratacao__c);
System.debug('Status: ' + check.Status__c);
System.debug('Direito: ' + check.Dias_Direito__c);
System.debug('Tirados: ' + check.Dias_Tirados__c);
System.debug('Abono Vendidos: ' + check.Dias_Abono_Vendidos__c);
System.debug('Disponiveis: ' + check.Dias_Disponiveis__c);
System.debug('Aquisitivo: ' + check.Periodo_Aquisitivo_Inicio__c + ' a ' + check.Periodo_Aquisitivo_Fim__c);
System.debug('Concessivo ate: ' + check.Periodo_Concessivo_Fim__c);
