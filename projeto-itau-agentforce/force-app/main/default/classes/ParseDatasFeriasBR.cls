/**
 * Parser deterministico de datas para agendamento de ferias (padrao BR DD/MM/AAAA
 * ou ISO YYYY-MM-DD). O segundo segmento em DD/MM/AAAA e sempre o MES.
 * Destinado a ser chamado pelo Agent antes de enviar ISO ao Flow.
 */
public without sharing class ParseDatasFeriasBR {
    private static final Pattern ISO = Pattern.compile('^(\\d{4})-(\\d{2})-(\\d{2})$');
    private static final Pattern BR = Pattern.compile('^(\\d{1,2})/(\\d{1,2})/(\\d{4})$');

    @InvocableMethod(
        label='Parse Datas Ferias BR'
        description='Converte texto DD/MM/AAAA (BR) ou YYYY-MM-DD em datas ISO para o Flow. Mes e o segundo numero em formato BR.'
    )
    public static List<Result> parse(List<Request> requests) {
        List<Result> out = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            out.add(fail('Nenhuma entrada.'));
            return out;
        }
        for (Request req : requests) {
            out.add(parseOne(req));
        }
        return out;
    }

    private static Result parseOne(Request req) {
        if (req == null) {
            return fail('Requisicao invalida.');
        }
        String tIni = req.textoDataInicio == null ? '' : req.textoDataInicio.trim();
        String tFim = req.textoDataRetorno == null ? '' : req.textoDataRetorno.trim();
        if (String.isBlank(tIni) || String.isBlank(tFim)) {
            return fail('Informe data de inicio e data de retorno (DD/MM/AAAA ou ISO).');
        }
        Date dIni = parseFlexible(tIni);
        Date dFim = parseFlexible(tFim);
        if (dIni == null) {
            return fail('Data de inicio invalida ou formato nao reconhecido: ' + tIni);
        }
        if (dFim == null) {
            return fail('Data de retorno invalida ou formato nao reconhecido: ' + tFim);
        }
        Result ok = new Result();
        ok.success = true;
        ok.message = null;
        ok.dataInicioIso = toIso(dIni);
        ok.dataRetornoIso = toIso(dFim);
        return ok;
    }

    private static Result fail(String msg) {
        Result r = new Result();
        r.success = false;
        r.message = msg;
        r.dataInicioIso = null;
        r.dataRetornoIso = null;
        return r;
    }

    @TestVisible
    static Date parseFlexible(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        Matcher mIso = ISO.matcher(s);
        if (mIso.matches()) {
            try {
                Integer y = Integer.valueOf(mIso.group(1));
                Integer mo = Integer.valueOf(mIso.group(2));
                Integer d = Integer.valueOf(mIso.group(3));
                Date cand = Date.newInstance(y, mo, d);
                return (cand.year() == y && cand.month() == mo && cand.day() == d) ? cand : null;
            } catch (Exception e) {
                return null;
            }
        }
        Matcher mBr = BR.matcher(s);
        if (mBr.matches()) {
            try {
                Integer day = Integer.valueOf(mBr.group(1));
                Integer month = Integer.valueOf(mBr.group(2));
                Integer year = Integer.valueOf(mBr.group(3));
                Date cand = Date.newInstance(year, month, day);
                return (cand.year() == year && cand.month() == month && cand.day() == day) ? cand : null;
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }

    private static String toIso(Date d) {
        String mo = d.month() < 10 ? '0' + String.valueOf(d.month()) : String.valueOf(d.month());
        String da = d.day() < 10 ? '0' + String.valueOf(d.day()) : String.valueOf(d.day());
        return String.valueOf(d.year()) + '-' + mo + '-' + da;
    }

    public class Request {
        @InvocableVariable(label='Texto data inicio (DD/MM/AAAA ou ISO)')
        public String textoDataInicio;

        @InvocableVariable(label='Texto data retorno (DD/MM/AAAA ou ISO)')
        public String textoDataRetorno;
    }

    public class Result {
        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem de erro')
        public String message;

        @InvocableVariable(label='Data inicio ISO (YYYY-MM-DD)')
        public String dataInicioIso;

        @InvocableVariable(label='Data retorno ISO (YYYY-MM-DD)')
        public String dataRetornoIso;
    }
}
