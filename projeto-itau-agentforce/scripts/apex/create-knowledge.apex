/**
 * Cria (ou atualiza) e publica os 5 artigos de politica de RH do Banco Itau.
 * Idempotente: artigos ja publicados com o mesmo UrlName sao ignorados.
 *
 * Executar via:
 *   sf apex run -f scripts/apex/create-knowledge.apex -o AgentforceSysmapEmpreendimentos
 */

// ---------------------------------------------------------------------------
// Descoberta do RecordType Politica_RH
// ---------------------------------------------------------------------------
Schema.RecordTypeInfo rtInfo = Knowledge__kav.SObjectType
    .getDescribe()
    .getRecordTypeInfosByDeveloperName()
    .get('Politica_RH');

if (rtInfo == null) {
    throw new System.IllegalArgumentException('RecordType Politica_RH nao encontrado em Knowledge__kav.');
}
Id politicaRtId = rtInfo.getRecordTypeId();

// ---------------------------------------------------------------------------
// Definicao dos artigos (HTML ja renderizado)
// ---------------------------------------------------------------------------
class Artigo {
    public String title;
    public String urlName;
    public String summary;
    public String conteudoHtml;
    public String fonteLegal;
    public Date ultimaRevisao;
    public List<String> categorias; // API names dentro de Topicos_RH
    public Artigo(String t, String u, String s, String html, String fl, Date dt, List<String> cats) {
        this.title = t;
        this.urlName = u;
        this.summary = s;
        this.conteudoHtml = html;
        this.fonteLegal = fl;
        this.ultimaRevisao = dt;
        this.categorias = cats;
    }
}

List<Artigo> artigos = new List<Artigo>();

artigos.add(new Artigo(
    'Ferias CLT: Regras Gerais no Banco Itau',
    'ferias-clt-regras-gerais',
    'Direito a 30 dias, periodo aquisitivo e concessivo, adicional de 1/3 e consequencias do atraso na concessao.',
    '<h2>Direito a 30 dias</h2>'
    + '<p>Todo colaborador CLT do Itau adquire direito a <b>30 dias corridos de ferias remuneradas</b> apos completar 12 meses de trabalho, conforme art. 130 da CLT.</p>'
    + '<p>A quantidade de dias pode ser reduzida em caso de faltas injustificadas no periodo:</p>'
    + '<ul>'
    + '<li>Ate 5 faltas: 30 dias</li>'
    + '<li>De 6 a 14 faltas: 24 dias</li>'
    + '<li>De 15 a 23 faltas: 18 dias</li>'
    + '<li>De 24 a 32 faltas: 12 dias</li>'
    + '<li>33 ou mais: perde o direito</li>'
    + '</ul>'
    + '<h2>Periodo aquisitivo e concessivo</h2>'
    + '<ul>'
    + '<li><b>Aquisitivo:</b> 12 meses em que voce "ganha" o direito as ferias.</li>'
    + '<li><b>Concessivo:</b> mais 12 meses que a empresa tem para conceder as ferias.</li>'
    + '</ul>'
    + '<p>Exemplo: admissao em 01/03/2025. Aquisitivo termina em 28/02/2026. A partir dessa data, o Itau tem ate 28/02/2027 (concessivo) para conceder as ferias.</p>'
    + '<h2>Adicional de 1/3 constitucional</h2>'
    + '<p>O pagamento e feito ate <b>2 dias antes do inicio</b> das ferias e inclui o adicional constitucional de <b>1/3 do salario</b> (art. 7, XVII, CF).</p>'
    + '<h2>Se as ferias nao forem concedidas no prazo</h2>'
    + '<p>Caso o periodo concessivo se encerre sem que as ferias sejam tiradas, o Itau deve paga-las <b>em dobro</b> (art. 137 CLT). Por isso, sempre programe suas ferias com antecedencia via I-Connecta.</p>'
    + '<h2>Como solicitar</h2>'
    + '<p>Abra o chat do I-Connecta e diga <b>"quero marcar minhas ferias"</b>. O assistente virtual guiara voce pelo processo em poucos passos.</p>',
    'CLT arts. 129-153 | Reforma Trabalhista Lei 13.467/2017 | CF art. 7, XVII',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Fracionamento de Ferias (Reforma Trabalhista)',
    'fracionamento-ferias',
    'Divisao das ferias em ate 3 periodos, respeitando regra de minimo 14 dias + 5 + 5.',
    '<p>Desde a Reforma Trabalhista (Lei 13.467/2017), voce pode <b>dividir suas ferias em ate 3 periodos</b> no mesmo aquisitivo, respeitando as regras abaixo.</p>'
    + '<h2>Regras do fracionamento</h2>'
    + '<ol>'
    + '<li>Um dos periodos deve ter <b>no minimo 14 dias corridos</b>.</li>'
    + '<li>Os outros dois periodos devem ter <b>no minimo 5 dias corridos cada</b>.</li>'
    + '<li>O total nunca pode ultrapassar os dias de direito do aquisitivo.</li>'
    + '<li>O fracionamento depende de concordancia do colaborador - o Itau nao pode impor.</li>'
    + '<li>Ferias nao podem iniciar <b>2 dias antes</b> de feriado ou descanso semanal remunerado (art. 134, par. 3).</li>'
    + '</ol>'
    + '<h2>Exemplos validos (direito = 30 dias)</h2>'
    + '<ul><li>14 + 10 + 6</li><li>20 + 5 + 5</li><li>15 + 15</li><li>30 (sem fracionar)</li></ul>'
    + '<h2>Exemplos invalidos</h2>'
    + '<ul>'
    + '<li>10 + 10 + 10: nenhum periodo tem 14 dias.</li>'
    + '<li>18 + 4 + 8: tem periodo com menos de 5 dias.</li>'
    + '<li>14 + 10 + 4 + 2: passa de 3 periodos.</li>'
    + '</ul>'
    + '<h2>Dica pratica</h2>'
    + '<p>Ao marcar no I-Connecta, o assistente ja valida automaticamente essas regras e so permite configuracoes dentro da CLT.</p>',
    'CLT art. 134, par. 1 a 3 | Lei 13.467/2017',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Abono Pecuniario: Vender Parte das Ferias',
    'abono-pecuniario-venda-ferias',
    'Conversao de ate 1/3 das ferias em dinheiro, regras, prazos e limites.',
    '<p>O <b>abono pecuniario</b>, popularmente chamado de "venda de ferias", e o direito de converter parte das suas ferias em dinheiro.</p>'
    + '<h2>Quanto posso vender?</h2>'
    + '<p><b>Ate 1/3 do periodo.</b> Se voce tem direito a 30 dias, pode vender <b>no maximo 10 dias</b>, ficando com 20 dias de descanso efetivo.</p>'
    + '<ul>'
    + '<li>Direito 30 dias: ate 10 de abono / 20 de descanso</li>'
    + '<li>Direito 24 dias: ate 8 de abono / 16 de descanso</li>'
    + '<li>Direito 18 dias: ate 6 de abono / 12 de descanso</li>'
    + '<li>Direito 12 dias: ate 4 de abono / 8 de descanso</li>'
    + '</ul>'
    + '<h2>Prazo para solicitar</h2>'
    + '<p>A solicitacao do abono deve ser feita <b>ate 15 dias antes do termino do periodo aquisitivo</b> (art. 143 CLT). Fora desse prazo, a conversao nao e garantida.</p>'
    + '<h2>Quanto vou receber?</h2>'
    + '<p>Formula: (salario bruto x dias vendidos / 30) + adicional de 1/3 sobre esse valor.</p>'
    + '<p>Exemplo - salario R$ 6.000, 10 dias vendidos:</p>'
    + '<ul>'
    + '<li>Proporcional: 6.000 x 10/30 = R$ 2.000</li>'
    + '<li>Adicional de 1/3: R$ 666,67</li>'
    + '<li>Total bruto: R$ 2.666,67 (sujeito a INSS e IR)</li>'
    + '</ul>'
    + '<h2>Como solicitar no Itau</h2>'
    + '<p>Ao marcar suas ferias via I-Connecta, voce vera uma opcao <b>"Desejo vender parte das ferias como abono pecuniario"</b>. Basta marca-la e indicar quantos dias deseja converter - o sistema ja valida o limite de 1/3 automaticamente.</p>',
    'CLT art. 143',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Diferencas entre Ferias CLT e PJ no Itau',
    'ferias-clt-vs-pj',
    'Comparativo entre regime CLT (lei) e PJ (contrato) para afastamento remunerado.',
    '<p>Colaboradores CLT e PJ seguem regras distintas para afastamentos. Veja abaixo o comparativo.</p>'
    + '<h2>Resumo</h2>'
    + '<ul>'
    + '<li><b>Dias por ano:</b> CLT ate 30 corridos | PJ 20 uteis.</li>'
    + '<li><b>Adicional de 1/3:</b> CLT sim (constitucional) | PJ nao aplicavel.</li>'
    + '<li><b>Abono pecuniario:</b> CLT ate 1/3 (10 dias) | PJ nao aplicavel.</li>'
    + '<li><b>Aviso minimo:</b> CLT 30 dias | PJ 15 dias.</li>'
    + '<li><b>Fracionamento:</b> CLT ate 3 periodos com regras CLT | PJ livre, conforme combinado.</li>'
    + '<li><b>Pagamento:</b> CLT ate 2 dias antes do gozo | PJ conforme fatura mensal normal.</li>'
    + '</ul>'
    + '<h2>Como funciona para CLT</h2>'
    + '<p>Direitos constitucionais e trabalhistas se aplicam integralmente. Todas as regras dos artigos relacionados se aplicam.</p>'
    + '<h2>Como funciona para PJ no Itau</h2>'
    + '<p>Como prestador de servicos PJ voce nao tem vinculo trabalhista. O Itau reconhece, por contrato, o direito a afastamento remunerado nestes termos:</p>'
    + '<ol>'
    + '<li>20 dias uteis por ano de contrato (aproximadamente 4 semanas).</li>'
    + '<li>O afastamento e planejado junto ao gestor com minimo de 15 dias de antecedencia.</li>'
    + '<li>Durante o afastamento, o valor contratual mensal continua sendo pago normalmente - nao ha adicional.</li>'
    + '<li>Nao ha conceito de "venda" de dias.</li>'
    + '<li>O fracionamento e flexivel, respeitando operacao do time.</li>'
    + '</ol>'
    + '<h2>Se eu mudar de regime (PJ -> CLT ou vice-versa)?</h2>'
    + '<p>A contagem recomeca na data da mudanca. Tempo anterior em outro regime <b>nao e somado</b> para o calculo do aquisitivo.</p>'
    + '<h2>Como solicitar</h2>'
    + '<p>Em ambos os casos, abra o chat do I-Connecta e peca para marcar seu afastamento. O sistema detecta automaticamente seu regime e aplica as regras corretas.</p>',
    'CLT arts. 129-153 | Contrato-padrao de prestacao de servicos Itau (PJ)',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Beneficios Durante as Ferias e Politica de Home Office',
    'beneficios-ferias-home-office',
    'O que continua, o que e suspenso durante as ferias e politica de trabalho hibrido no retorno.',
    '<h2>Durante as ferias</h2>'
    + '<h3>O que voce continua recebendo</h3>'
    + '<ul>'
    + '<li>Plano de saude - cobertura integral mantida para voce e dependentes.</li>'
    + '<li>Plano odontologico - idem.</li>'
    + '<li>Vale alimentacao / refeicao - creditado normalmente.</li>'
    + '<li>Seguro de vida - vigente.</li>'
    + '<li>Participacao em resultados (PLR) - contabilizada proporcionalmente.</li>'
    + '</ul>'
    + '<h3>O que e suspenso</h3>'
    + '<ul>'
    + '<li>Vale transporte - suspenso durante os dias de ferias.</li>'
    + '<li>Auxilio creche - mantido se aplicavel ao seu caso.</li>'
    + '<li>Gympass / Wellhub - mantido.</li>'
    + '</ul>'
    + '<h3>O que pode ser afetado</h3>'
    + '<ul>'
    + '<li>Metas comerciais do mes: conversadas com seu gestor antes do inicio.</li>'
    + '<li>Projetos sob sua responsabilidade: e obrigatorio deixar handover documentado.</li>'
    + '</ul>'
    + '<h2>Politica de Home Office (I-Connecta Hibrido)</h2>'
    + '<p>O Itau adota regime hibrido com <b>3 dias presenciais + 2 dias remotos por semana</b>, valido inclusive no retorno das ferias.</p>'
    + '<h3>Equipamentos</h3>'
    + '<ul>'
    + '<li>Laptop corporativo, cracha e token continuam com voce durante as ferias.</li>'
    + '<li>Nao e necessario devolver ou desligar equipamentos.</li>'
    + '<li>Em caso de viagem internacional, avise a Seguranca da Informacao com 7 dias de antecedencia.</li>'
    + '</ul>'
    + '<h3>Acesso remoto</h3>'
    + '<ul>'
    + '<li>VPN continua ativa, mas <b>nao entre no sistema em dias de ferias</b>. Isso pode descaracterizar o gozo legal das ferias (art. 129 CLT) e gerar pendencia trabalhista.</li>'
    + '</ul>'
    + '<h3>Emergencias</h3>'
    + '<ul>'
    + '<li>Se houver emergencia do time, seu gestor entrara em contato pelo telefone pessoal cadastrado no RH.</li>'
    + '<li>Responder a e-mails eventuais nao e considerado interrupcao de ferias se nao houver retorno ao trabalho efetivo.</li>'
    + '</ul>',
    'Politicas internas Itau - RH | Acordo Coletivo Bancarios | CLT art. 129',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Beneficios', 'Home_Office'}
));

// ---------------------------------------------------------------------------
// Upsert + publicacao
// ---------------------------------------------------------------------------
Set<String> urlNames = new Set<String>();
for (Artigo a : artigos) { urlNames.add(a.urlName); }

// Ja publicados: pula
Map<String, Knowledge__kav> existentesOnline = new Map<String, Knowledge__kav>();
for (Knowledge__kav kav : [
    SELECT Id, KnowledgeArticleId, UrlName, PublishStatus, IsLatestVersion
    FROM Knowledge__kav
    WHERE UrlName IN :urlNames AND PublishStatus = 'Online' AND Language = 'pt_BR'
]) {
    existentesOnline.put(kav.UrlName, kav);
}

Integer criados = 0;
Integer pulados = 0;

for (Artigo a : artigos) {
    if (existentesOnline.containsKey(a.urlName)) {
        System.debug('PULANDO (ja online): ' + a.urlName);
        pulados++;
        continue;
    }

    Knowledge__kav kav = new Knowledge__kav(
        RecordTypeId         = politicaRtId,
        Title                = a.title,
        UrlName              = a.urlName,
        Summary              = a.summary,
        Language             = 'pt_BR',
        Politica_Conteudo__c = a.conteudoHtml,
        Politica_Fonte_Legal__c = a.fonteLegal,
        Politica_Ultima_Revisao__c = a.ultimaRevisao
    );
    insert kav;

    // Requery para obter KnowledgeArticleId (nao e populado em memoria apos insert)
    Knowledge__kav kavFull = [
        SELECT Id, KnowledgeArticleId
        FROM Knowledge__kav
        WHERE Id = :kav.Id
        LIMIT 1
    ];

    // Vincula data categories
    List<Knowledge__DataCategorySelection> dcs = new List<Knowledge__DataCategorySelection>();
    for (String cat : a.categorias) {
        dcs.add(new Knowledge__DataCategorySelection(
            ParentId          = kavFull.Id,
            DataCategoryGroupName = 'Topicos_RH',
            DataCategoryName      = cat
        ));
    }
    if (!dcs.isEmpty()) insert dcs;

    // Publica o artigo (flagAsNew=true)
    KbManagement.PublishingService.publishArticle(kavFull.KnowledgeArticleId, true);

    criados++;
    System.debug('PUBLICADO: ' + a.urlName);
}

System.debug('>>> Artigos criados: ' + criados + ' | pulados (ja online): ' + pulados);
