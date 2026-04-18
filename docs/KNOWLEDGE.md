# Knowledge Base — Políticas de RH do Itaú

Esta base é o "cérebro" do **Agente A (Informativo)**. Os 5 artigos cobrem as perguntas mais comuns dos colaboradores sobre férias, benefícios e trabalho híbrido.

## Metadata criada

### Data Category Group `Topicos_RH`

Categorias (hierarquia):

```
Topicos_RH
└── All (Todos)
    ├── Ferias
    ├── Beneficios
    └── Home_Office
```

Arquivo: `force-app/main/default/dataCategoryGroups/Topicos_RH.datacategorygroup-meta.xml`

### Record Type `Knowledge__kav.Politica_RH`

- **DeveloperName:** `Politica_RH`
- **Label:** Política RH
- **Uso:** artigos de política interna de RH consumidos pelo Agente A.

Coexiste com os Record Types pré-existentes da Brasal SDO (`SDO_Knowledge_Cirrus`, `SDO_Knowledge_FAQ`, `SDO_Knowledge_KCSArticle`) sem conflito.

### Custom Fields em `Knowledge__kav`

| API Name | Tipo | Tamanho | Descrição |
|---|---|---|---|
| `Politica_Conteudo__c` | Rich Text (HTML) | 131072 | Corpo do artigo renderizado |
| `Politica_Fonte_Legal__c` | Text | 255 | Base normativa (CLT, Leis, políticas internas) |
| `Politica_Ultima_Revisao__c` | Date | — | Data da última revisão pelo RH |

### FLS e Record Type Visibility

Adicionados aos dois permission sets:

- `Agentforce_RH_Colaborador` — read-only em Knowledge
- `Agentforce_RH_Gestor` — read-only em Knowledge

Ambos recebem `recordTypeVisibilities` para `Knowledge__kav.Politica_RH`.

## Artigos publicados

| UrlName | Title | Categorias |
|---|---|---|
| `ferias-clt-regras-gerais` | Férias CLT: Regras Gerais no Banco Itaú | Ferias |
| `fracionamento-ferias` | Fracionamento de Férias (Reforma Trabalhista) | Ferias |
| `abono-pecuniario-venda-ferias` | Abono Pecuniário: Vender Parte das Férias | Ferias |
| `ferias-clt-vs-pj` | Diferenças entre Férias CLT e PJ no Itaú | Ferias |
| `beneficios-ferias-home-office` | Benefícios Durante as Férias e Política de Home Office | Beneficios, Home_Office |

Conteúdo-fonte em markdown: `docs/knowledge-articles/*.md`.
Conteúdo HTML embutido no script Apex: `scripts/apex/create-knowledge.apex`.

## Como deployar e popular

```bash
# 1. Deploy do metadata (já coberto por deploy.sh quando rodado completo)
sf project deploy start -o <alias> \
  -m "CustomField:Knowledge__kav.Politica_Conteudo__c" \
  -m "CustomField:Knowledge__kav.Politica_Fonte_Legal__c" \
  -m "CustomField:Knowledge__kav.Politica_Ultima_Revisao__c" \
  -m "RecordType:Knowledge__kav.Politica_RH" \
  -m "DataCategoryGroup:Topicos_RH"

# 2. Deploy dos permission sets atualizados
sf project deploy start -o <alias> \
  -m "PermissionSet:Agentforce_RH_Colaborador" \
  -m "PermissionSet:Agentforce_RH_Gestor"

# 3. Criar e publicar os 5 artigos (idempotente)
./scripts/create-knowledge.sh <alias>
```

## Idempotência

O script `create-knowledge.sh` (Apex `create-knowledge.apex`) consulta artigos com `PublishStatus = 'Online'` e `Language = 'pt_BR'` pelo `UrlName`. Se todos os 5 já estiverem online, o script roda sem criar duplicatas.

Para **republicar** um artigo (ex.: após editar o conteúdo), primeiro arquive a versão atual no app Knowledge, ou apague o registro via:

```bash
sf data query -o <alias> -q "SELECT Id FROM Knowledge__kav WHERE UrlName='ferias-clt-regras-gerais' AND PublishStatus='Online'" --json
# Copie o Id e rode:
sf apex run -o <alias> --apex-code "KbManagement.PublishingService.archiveOnlineArticle('<knowledgeArticleId>', Date.today());"
```

## Pré-requisitos na org

- **Knowledge ativado** (Setup → Knowledge Settings → marcar "Yes, enable Lightning Knowledge"). Isso **não é deployável via Metadata API** — é setting interno. A org Brasal SDO **já tem Knowledge ativado** (validado em runtime).
- **Idioma pt_BR** habilitado como Knowledge Language (Setup → Language Settings → adicionar Brazilian Portuguese).

## Próximo passo — Agente A

Com o Knowledge publicado, o **Topic `Consulta_Politicas_RH`** do Agente A deve ser configurado com:

- **Scope:** "Responder perguntas sobre políticas internas de RH do Itaú usando exclusivamente os artigos publicados em `Topicos_RH`."
- **Instructions:** sempre citar a fonte legal e a data da última revisão; nunca inventar regras além do que está nos artigos.
- **Actions:** `Search Knowledge Articles` (standard) filtrando por `RecordType = Politica_RH` e `DataCategoryGroup = Topicos_RH`.

Veja `docs/ARQUITETURA.md` seção "Agente A" para detalhes.
