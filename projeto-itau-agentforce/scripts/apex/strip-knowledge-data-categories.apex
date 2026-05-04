/**
 * Remove Knowledge__DataCategorySelection rows for Politica_RH articles (Topicos_RH).
 * LEX list views aplicam visibilidade por data category; colaboradores sem ALL no grupo veem lista vazia.
 *
 * Uso: sf apex run -f scripts/apex/strip-knowledge-data-categories.apex -o <alias>
 */
List<Knowledge__DataCategorySelection> rows = [
    SELECT Id, DataCategoryGroupName
    FROM Knowledge__DataCategorySelection
    WHERE ParentId IN (SELECT Id FROM Knowledge__kav WHERE RecordType.DeveloperName = 'Politica_RH')
];
List<Knowledge__DataCategorySelection> toDel = new List<Knowledge__DataCategorySelection>();
for (Knowledge__DataCategorySelection r : rows) {
    if (r.DataCategoryGroupName == 'Topicos_RH') {
        toDel.add(r);
    }
}
if (toDel.isEmpty()) {
    System.debug('>>> Nenhuma selecao Topicos_RH em Politica_RH para remover.');
} else {
    delete toDel;
    System.debug('>>> Removidas ' + toDel.size() + ' linhas Knowledge__DataCategorySelection.');
}
