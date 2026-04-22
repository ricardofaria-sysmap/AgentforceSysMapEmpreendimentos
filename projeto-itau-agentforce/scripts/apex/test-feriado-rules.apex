// Testa R6 (inicio em feriado) com datas futuras que passam pelo R1 (30 dias).

List<Map<String, Object>> casos = new List<Map<String, Object>>{
    // 7/Set/2026 = segunda (Independencia). Nao bloqueada por R5 (seg). Deve bloquear por R6 (eh feriado).
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,9,7),  'retorno' => Date.newInstance(2026,9,16), 'esperado' => 'R6 - inicio em feriado (Independencia, seg)' },
    // 2/Nov/2026 = segunda (Finados). R6.
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,11,2), 'retorno' => Date.newInstance(2026,11,11),'esperado' => 'R6 - inicio em feriado (Finados, seg)' },
    // 3/Nov/2026 = terca. +1=4/11 nao feriado. +2=5/11 nao. Mas 2/11 eh feriado, portanto 3/11 vem DEPOIS de feriado (ok).
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,11,3), 'retorno' => Date.newInstance(2026,11,12),'esperado' => 'OK - terca, sem feriado no range [3/11, 5/11]' },
    // 13/Nov/2026 = sexta. R5 bloqueia por ser sex. Tambem +2=15/11 feriado. Mas R5 dispara primeiro.
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,11,13),'retorno' => Date.newInstance(2026,11,22),'esperado' => 'R5 - sexta' },
    // 13/Out/2026 = terca. +1=14/10 nao. +2=15/10 nao. 12/10=feriado mas inicio=13/10 vem DEPOIS (ok).
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,10,13),'retorno' => Date.newInstance(2026,10,22),'esperado' => 'OK - terca pos-feriado' },
    // 21/Dez/2026 = segunda. +1=22/12 nao. +2=23/12 nao. 25/12 feriado mas esta FORA do range [21,23]. OK.
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,12,21),'retorno' => Date.newInstance(2026,12,30),'esperado' => 'OK - segunda, 21/12 eh 4 dias antes de 25/12' },
    // 23/Dez/2026 = quarta. +1=24/12 nao feriado. +2=25/12 FERIADO. Deve bloquear R7.
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,12,23),'retorno' => Date.newInstance(2027,1,1),  'esperado' => 'R7 - vespera de Natal (qua, +2=25/12)' },
    // 22/Dez/2026 = terca. +1=23/12 nao. +2=24/12 nao. 25/12 fora do range. Ok pela regra feriado, mas R5... terca=3. OK.
    new Map<String, Object>{ 'inicio' => Date.newInstance(2026,12,22),'retorno' => Date.newInstance(2026,12,31),'esperado' => 'OK - terca 22/12 (3 dias antes de 25/12 sai do range de 2)' }
};

String[] dias = new String[]{'Dom','Seg','Ter','Qua','Qui','Sex','Sab'};

for (Map<String, Object> c : casos) {
    Date inicio = (Date) c.get('inicio');
    Date retorno = (Date) c.get('retorno');
    String esperado = (String) c.get('esperado');
    Integer weekday = Math.mod(Date.newInstance(1900,1,7).daysBetween(inicio), 7) + 1;
    String dow = dias[weekday-1];

    Map<String, Object> inputs = new Map<String, Object>{
        'varUserId'      => UserInfo.getUserId(),
        'varDataInicio'  => inicio,
        'varDataRetorno' => retorno,
        'varVenderAbono' => false,
        'varDiasAbono'   => 0
    };
    Flow.Interview.Agendamento_Ferias_Autolaunch flow = new Flow.Interview.Agendamento_Ferias_Autolaunch(inputs);

    Savepoint sp = Database.setSavepoint();
    String resultado;
    try {
        flow.start();
        Boolean sucesso = (Boolean) flow.getVariableValue('varSucesso');
        String msg = (String) flow.getVariableValue('varMensagemErro');
        String cn = (String) flow.getVariableValue('varCaseNumber');
        resultado = sucesso ? ('SUCESSO Case=' + cn) : ('ERRO: ' + msg);
    } catch (Exception e) {
        resultado = 'EXCEPTION: ' + e.getMessage();
    } finally {
        Database.rollback(sp);
    }

    System.debug('--- ' + inicio + ' (' + dow + ') a ' + retorno);
    System.debug('    Esperado: ' + esperado);
    System.debug('    Obtido:   ' + resultado);
}
