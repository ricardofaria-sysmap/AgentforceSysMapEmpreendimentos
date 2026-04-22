public with sharing class ConsultarPoliticasRH {

    private static final Integer MAX_RESULTS = 5;

    @InvocableMethod(
        label='Consultar Politicas RH (Knowledge)'
        description='Busca artigos publicados de Knowledge na Data Category Topicos_RH filtrando por palavra-chave. Retorna lista achatada (titulo, resumo, conteudo, fonte legal, url) para o Agent compor resposta com citacao obrigatoria.'
    )
    public static List<Result> consultar(List<Request> requests) {
        List<Result> out = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return out;
        }

        for (Request req : requests) {
            Result r = new Result();
            r.success = false;
            r.articles = new List<Artigo>();

            if (req == null || String.isBlank(req.query)) {
                r.message = 'Palavra-chave (query) obrigatoria.';
                out.add(r);
                continue;
            }

            String needle = '%' + req.query.trim().toLowerCase() + '%';
            try {
                List<Knowledge__kav> kavs = [
                    SELECT Id, Title, UrlName, Summary, ArticleNumber,
                           Politica_Fonte_Legal__c, Politica_Conteudo__c,
                           Politica_Ultima_Revisao__c, LastPublishedDate
                    FROM Knowledge__kav
                    WHERE PublishStatus = 'Online'
                      AND Language = 'pt_BR'
                      AND (Title LIKE :needle OR Summary LIKE :needle)
                    WITH USER_MODE
                    ORDER BY LastPublishedDate DESC
                    LIMIT :MAX_RESULTS
                ];

                for (Knowledge__kav k : kavs) {
                    Artigo a = new Artigo();
                    a.titulo = k.Title;
                    a.resumo = k.Summary;
                    a.conteudo = resumirConteudo(k.Politica_Conteudo__c, 1200);
                    a.urlName = k.UrlName;
                    a.numero = k.ArticleNumber;
                    a.fonteLegal = k.Politica_Fonte_Legal__c;
                    a.ultimaRevisao = k.Politica_Ultima_Revisao__c;
                    r.articles.add(a);
                }

                r.totalEncontrados = r.articles.size();
                r.success = !r.articles.isEmpty();
                if (r.articles.isEmpty()) {
                    r.message = 'Nenhum artigo encontrado para "' + req.query + '". Sugira outra palavra-chave ou transfira para atendimento humano.';
                }
            } catch (Exception e) {
                r.message = 'Erro ao consultar Knowledge: ' + e.getMessage();
            }
            out.add(r);
        }
        return out;
    }

    private static String resumirConteudo(String raw, Integer limite) {
        if (String.isBlank(raw)) return null;
        String semHtml = raw.replaceAll('<[^>]+>', ' ').replaceAll('\\s+', ' ').trim();
        return semHtml.length() <= limite ? semHtml : semHtml.substring(0, limite) + '...';
    }

    public class Request {
        @InvocableVariable(label='Palavra-chave de busca' required=true)
        public String query;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem')
        public String message;

        @InvocableVariable(label='Total de artigos encontrados')
        public Integer totalEncontrados;

        @InvocableVariable(label='Artigos encontrados')
        public List<Artigo> articles;
    }

    public class Artigo {
        @InvocableVariable(label='Titulo')
        public String titulo;

        @InvocableVariable(label='Resumo (Summary do artigo)')
        public String resumo;

        @InvocableVariable(label='Conteudo (limitado a 1200 chars, sem HTML)')
        public String conteudo;

        @InvocableVariable(label='UrlName')
        public String urlName;

        @InvocableVariable(label='Numero do artigo')
        public String numero;

        @InvocableVariable(label='Fonte legal')
        public String fonteLegal;

        @InvocableVariable(label='Ultima revisao')
        public Date ultimaRevisao;
    }
}
