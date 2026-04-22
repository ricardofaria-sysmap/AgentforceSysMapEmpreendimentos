/**
 * Cria ou atualiza e publica os 5 artigos de politica de RH do Banco Itau.
 * Idempotente: se o artigo ja existe online com o mesmo UrlName, abre um draft
 * (editOnlineArticle), atualiza o conteudo e republica. Se nao existe, cria.
 *
 * Titulos e summaries com acentuacao portuguesa correta (PT-BR). O conteudo HTML
 * tambem usa acentos. O Apex ConsultarPoliticasRH usa SOSL (accent-insensitive)
 * para busca, entao queries com ou sem acento casam.
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
// Definicao dos artigos (com acentuacao correta)
// ---------------------------------------------------------------------------
class Artigo {
    public String title;
    public String urlName;
    public String summary;
    public String conteudoHtml;
    public String fonteLegal;
    public Date ultimaRevisao;
    public List<String> categorias;
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
    'Férias CLT: Regras Gerais no Banco Itaú',
    'ferias-clt-regras-gerais',
    'Direito a 30 dias, período aquisitivo e concessivo, adicional de 1/3 e consequências do atraso na concessão.',
    '<h2>Direito a 30 dias</h2>'
    + '<p>Todo colaborador CLT do Itaú adquire direito a <b>30 dias corridos de férias remuneradas</b> após completar 12 meses de trabalho, conforme art. 130 da CLT.</p>'
    + '<p>A quantidade de dias pode ser reduzida em caso de faltas injustificadas no período:</p>'
    + '<ul>'
    + '<li>Até 5 faltas: 30 dias</li>'
    + '<li>De 6 a 14 faltas: 24 dias</li>'
    + '<li>De 15 a 23 faltas: 18 dias</li>'
    + '<li>De 24 a 32 faltas: 12 dias</li>'
    + '<li>33 ou mais: perde o direito</li>'
    + '</ul>'
    + '<h2>Período aquisitivo e concessivo</h2>'
    + '<ul>'
    + '<li><b>Aquisitivo:</b> 12 meses em que você "ganha" o direito às férias.</li>'
    + '<li><b>Concessivo:</b> mais 12 meses que a empresa tem para conceder as férias.</li>'
    + '</ul>'
    + '<p>Exemplo: admissão em 01/03/2025. Aquisitivo termina em 28/02/2026. A partir dessa data, o Itaú tem até 28/02/2027 (concessivo) para conceder as férias.</p>'
    + '<h2>Adicional de 1/3 constitucional</h2>'
    + '<p>O pagamento é feito até <b>2 dias antes do início</b> das férias e inclui o adicional constitucional de <b>1/3 do salário</b> (art. 7º, XVII, CF).</p>'
    + '<h2>Se as férias não forem concedidas no prazo</h2>'
    + '<p>Caso o período concessivo se encerre sem que as férias sejam tiradas, o Itaú deve pagá-las <b>em dobro</b> (art. 137 CLT). Por isso, sempre programe suas férias com antecedência via I-Connecta.</p>'
    + '<h2>Como solicitar</h2>'
    + '<p>Abra o chat do I-Connecta e diga <b>"quero marcar minhas férias"</b>. O assistente virtual guiará você pelo processo em poucos passos.</p>',
    'CLT arts. 129-153 | Reforma Trabalhista Lei 13.467/2017 | CF art. 7º, XVII',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Fracionamento de Férias (Reforma Trabalhista)',
    'fracionamento-ferias',
    'Divisão das férias em até 3 períodos, respeitando regra de mínimo 14 dias + 5 + 5.',
    '<p>Desde a Reforma Trabalhista (Lei 13.467/2017), você pode <b>dividir suas férias em até 3 períodos</b> no mesmo aquisitivo, respeitando as regras abaixo.</p>'
    + '<h2>Regras do fracionamento</h2>'
    + '<ol>'
    + '<li>Um dos períodos deve ter <b>no mínimo 14 dias corridos</b>.</li>'
    + '<li>Os outros dois períodos devem ter <b>no mínimo 5 dias corridos cada</b>.</li>'
    + '<li>O total nunca pode ultrapassar os dias de direito do aquisitivo.</li>'
    + '<li>O fracionamento depende de concordância do colaborador — o Itaú não pode impor.</li>'
    + '<li>Férias não podem iniciar <b>2 dias antes</b> de feriado ou descanso semanal remunerado (art. 134, § 3º).</li>'
    + '</ol>'
    + '<h2>Exemplos válidos (direito = 30 dias)</h2>'
    + '<ul><li>14 + 10 + 6</li><li>20 + 5 + 5</li><li>15 + 15</li><li>30 (sem fracionar)</li></ul>'
    + '<h2>Exemplos inválidos</h2>'
    + '<ul>'
    + '<li>10 + 10 + 10: nenhum período tem 14 dias.</li>'
    + '<li>18 + 4 + 8: tem período com menos de 5 dias.</li>'
    + '<li>14 + 10 + 4 + 2: passa de 3 períodos.</li>'
    + '</ul>'
    + '<h2>Dica prática</h2>'
    + '<p>Ao marcar no I-Connecta, o assistente já valida automaticamente essas regras e só permite configurações dentro da CLT.</p>',
    'CLT art. 134, § 1º a 3º | Lei 13.467/2017',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Abono Pecuniário: Vender Parte das Férias',
    'abono-pecuniario-venda-ferias',
    'Conversão de até 1/3 das férias em dinheiro, regras, prazos e limites.',
    '<p>O <b>abono pecuniário</b>, popularmente chamado de "venda de férias", é o direito de converter parte das suas férias em dinheiro.</p>'
    + '<h2>Quanto posso vender?</h2>'
    + '<p><b>Até 1/3 do período.</b> Se você tem direito a 30 dias, pode vender <b>no máximo 10 dias</b>, ficando com 20 dias de descanso efetivo.</p>'
    + '<ul>'
    + '<li>Direito 30 dias: até 10 de abono / 20 de descanso</li>'
    + '<li>Direito 24 dias: até 8 de abono / 16 de descanso</li>'
    + '<li>Direito 18 dias: até 6 de abono / 12 de descanso</li>'
    + '<li>Direito 12 dias: até 4 de abono / 8 de descanso</li>'
    + '</ul>'
    + '<h2>Prazo para solicitar</h2>'
    + '<p>A solicitação do abono deve ser feita <b>até 15 dias antes do término do período aquisitivo</b> (art. 143 CLT). Fora desse prazo, a conversão não é garantida.</p>'
    + '<h2>Quanto vou receber?</h2>'
    + '<p>Fórmula: (salário bruto × dias vendidos / 30) + adicional de 1/3 sobre esse valor.</p>'
    + '<p>Exemplo — salário R$ 6.000, 10 dias vendidos:</p>'
    + '<ul>'
    + '<li>Proporcional: 6.000 × 10/30 = R$ 2.000</li>'
    + '<li>Adicional de 1/3: R$ 666,67</li>'
    + '<li>Total bruto: R$ 2.666,67 (sujeito a INSS e IR)</li>'
    + '</ul>'
    + '<h2>Como solicitar no Itaú</h2>'
    + '<p>Ao marcar suas férias via I-Connecta, você verá uma opção <b>"Desejo vender parte das férias como abono pecuniário"</b>. Basta marcá-la e indicar quantos dias deseja converter — o sistema já valida o limite de 1/3 automaticamente.</p>',
    'CLT art. 143',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Diferenças entre Férias CLT e PJ no Itaú',
    'ferias-clt-vs-pj',
    'Comparativo entre regime CLT (lei) e PJ (contrato) para afastamento remunerado.',
    '<p>Colaboradores CLT e PJ seguem regras distintas para afastamentos. Veja abaixo o comparativo.</p>'
    + '<h2>Resumo</h2>'
    + '<ul>'
    + '<li><b>Dias por ano:</b> CLT até 30 corridos | PJ 20 úteis.</li>'
    + '<li><b>Adicional de 1/3:</b> CLT sim (constitucional) | PJ não aplicável.</li>'
    + '<li><b>Abono pecuniário:</b> CLT até 1/3 (10 dias) | PJ não aplicável.</li>'
    + '<li><b>Aviso mínimo:</b> CLT 30 dias | PJ 15 dias.</li>'
    + '<li><b>Fracionamento:</b> CLT até 3 períodos com regras CLT | PJ livre, conforme combinado.</li>'
    + '<li><b>Pagamento:</b> CLT até 2 dias antes do gozo | PJ conforme fatura mensal normal.</li>'
    + '</ul>'
    + '<h2>Como funciona para CLT</h2>'
    + '<p>Direitos constitucionais e trabalhistas se aplicam integralmente. Todas as regras dos artigos relacionados se aplicam.</p>'
    + '<h2>Como funciona para PJ no Itaú</h2>'
    + '<p>Como prestador de serviços PJ você não tem vínculo trabalhista. O Itaú reconhece, por contrato, o direito a afastamento remunerado nestes termos:</p>'
    + '<ol>'
    + '<li>20 dias úteis por ano de contrato (aproximadamente 4 semanas).</li>'
    + '<li>O afastamento é planejado junto ao gestor com mínimo de 15 dias de antecedência.</li>'
    + '<li>Durante o afastamento, o valor contratual mensal continua sendo pago normalmente — não há adicional.</li>'
    + '<li>Não há conceito de "venda" de dias.</li>'
    + '<li>O fracionamento é flexível, respeitando operação do time.</li>'
    + '</ol>'
    + '<h2>Se eu mudar de regime (PJ → CLT ou vice-versa)?</h2>'
    + '<p>A contagem recomeça na data da mudança. Tempo anterior em outro regime <b>não é somado</b> para o cálculo do aquisitivo.</p>'
    + '<h2>Como solicitar</h2>'
    + '<p>Em ambos os casos, abra o chat do I-Connecta e peça para marcar seu afastamento. O sistema detecta automaticamente seu regime e aplica as regras corretas.</p>',
    'CLT arts. 129-153 | Contrato-padrão de prestação de serviços Itaú (PJ)',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Ferias'}
));

artigos.add(new Artigo(
    'Benefícios Durante as Férias e Política de Home Office',
    'beneficios-ferias-home-office',
    'O que continua, o que é suspenso durante as férias e política de trabalho híbrido no retorno.',
    '<h2>Durante as férias</h2>'
    + '<h3>O que você continua recebendo</h3>'
    + '<ul>'
    + '<li>Plano de saúde — cobertura integral mantida para você e dependentes.</li>'
    + '<li>Plano odontológico — idem.</li>'
    + '<li>Vale alimentação / refeição — creditado normalmente.</li>'
    + '<li>Seguro de vida — vigente.</li>'
    + '<li>Participação em resultados (PLR) — contabilizada proporcionalmente.</li>'
    + '</ul>'
    + '<h3>O que é suspenso</h3>'
    + '<ul>'
    + '<li>Vale transporte — suspenso durante os dias de férias.</li>'
    + '<li>Auxílio creche — mantido se aplicável ao seu caso.</li>'
    + '<li>Gympass / Wellhub — mantido.</li>'
    + '</ul>'
    + '<h3>O que pode ser afetado</h3>'
    + '<ul>'
    + '<li>Metas comerciais do mês: conversadas com seu gestor antes do início.</li>'
    + '<li>Projetos sob sua responsabilidade: é obrigatório deixar handover documentado.</li>'
    + '</ul>'
    + '<h2>Política de Home Office (I-Connecta Híbrido)</h2>'
    + '<p>O Itaú adota regime híbrido com <b>3 dias presenciais + 2 dias remotos por semana</b>, válido inclusive no retorno das férias.</p>'
    + '<h3>Equipamentos</h3>'
    + '<ul>'
    + '<li>Laptop corporativo, crachá e token continuam com você durante as férias.</li>'
    + '<li>Não é necessário devolver ou desligar equipamentos.</li>'
    + '<li>Em caso de viagem internacional, avise a Segurança da Informação com 7 dias de antecedência.</li>'
    + '</ul>'
    + '<h3>Acesso remoto</h3>'
    + '<ul>'
    + '<li>VPN continua ativa, mas <b>não entre no sistema em dias de férias</b>. Isso pode descaracterizar o gozo legal das férias (art. 129 CLT) e gerar pendência trabalhista.</li>'
    + '</ul>'
    + '<h3>Emergências</h3>'
    + '<ul>'
    + '<li>Se houver emergência do time, seu gestor entrará em contato pelo telefone pessoal cadastrado no RH.</li>'
    + '<li>Responder a e-mails eventuais não é considerado interrupção de férias se não houver retorno ao trabalho efetivo.</li>'
    + '</ul>',
    'Políticas internas Itaú - RH | Acordo Coletivo Bancários | CLT art. 129',
    Date.newInstance(2026, 4, 17),
    new List<String>{'Beneficios', 'Home_Office'}
));

// ---------------------------------------------------------------------------
// Upsert + publicacao (idempotente)
// ---------------------------------------------------------------------------
Set<String> urlNames = new Set<String>();
for (Artigo a : artigos) { urlNames.add(a.urlName); }

// Mapa UrlName -> versao online atual
Map<String, Knowledge__kav> existentesOnline = new Map<String, Knowledge__kav>();
for (Knowledge__kav kav : [
    SELECT Id, KnowledgeArticleId, UrlName, PublishStatus, IsLatestVersion
    FROM Knowledge__kav
    WHERE UrlName IN :urlNames AND PublishStatus = 'Online' AND Language = 'pt_BR'
]) {
    existentesOnline.put(kav.UrlName, kav);
}

Integer criados = 0;
Integer atualizados = 0;

for (Artigo a : artigos) {
    Id kavId;
    Id kaId;

    if (existentesOnline.containsKey(a.urlName)) {
        // Existe online -> abre draft, atualiza e republica
        Knowledge__kav online = existentesOnline.get(a.urlName);
        kaId = online.KnowledgeArticleId;

        Id draftId = KbManagement.PublishingService.editOnlineArticle(kaId, true);

        Knowledge__kav draft = new Knowledge__kav(
            Id                         = draftId,
            Title                      = a.title,
            UrlName                    = a.urlName,
            Summary                    = a.summary,
            Politica_Conteudo__c       = a.conteudoHtml,
            Politica_Fonte_Legal__c    = a.fonteLegal,
            Politica_Ultima_Revisao__c = a.ultimaRevisao
        );
        update draft;

        kavId = draftId;
        atualizados++;
        System.debug('ATUALIZADO: ' + a.urlName);
    } else {
        // Nao existe -> cria do zero
        Knowledge__kav kav = new Knowledge__kav(
            RecordTypeId               = politicaRtId,
            Title                      = a.title,
            UrlName                    = a.urlName,
            Summary                    = a.summary,
            Language                   = 'pt_BR',
            Politica_Conteudo__c       = a.conteudoHtml,
            Politica_Fonte_Legal__c    = a.fonteLegal,
            Politica_Ultima_Revisao__c = a.ultimaRevisao
        );
        insert kav;

        Knowledge__kav kavFull = [
            SELECT Id, KnowledgeArticleId
            FROM Knowledge__kav
            WHERE Id = :kav.Id
            LIMIT 1
        ];
        kavId = kavFull.Id;
        kaId = kavFull.KnowledgeArticleId;

        criados++;
        System.debug('CRIADO: ' + a.urlName);
    }

    // Garante data categories vinculadas a esta versao draft/nova
    // (queries existentes ficam; se a versao nova ja herda, essa insercao pode falhar - tratamos)
    List<Knowledge__DataCategorySelection> dcsExistentes = [
        SELECT Id, DataCategoryName
        FROM Knowledge__DataCategorySelection
        WHERE ParentId = :kavId
    ];
    Set<String> catsJa = new Set<String>();
    for (Knowledge__DataCategorySelection d : dcsExistentes) { catsJa.add(d.DataCategoryName); }

    List<Knowledge__DataCategorySelection> dcsNovas = new List<Knowledge__DataCategorySelection>();
    for (String cat : a.categorias) {
        if (catsJa.contains(cat)) continue;
        dcsNovas.add(new Knowledge__DataCategorySelection(
            ParentId              = kavId,
            DataCategoryGroupName = 'Topicos_RH',
            DataCategoryName      = cat
        ));
    }
    if (!dcsNovas.isEmpty()) insert dcsNovas;

    // Publica (flagAsNew=false para update manter historico; true para artigos novos)
    Boolean flagAsNew = !existentesOnline.containsKey(a.urlName);
    KbManagement.PublishingService.publishArticle(kaId, flagAsNew);
}

System.debug('>>> Artigos criados: ' + criados + ' | atualizados: ' + atualizados);
