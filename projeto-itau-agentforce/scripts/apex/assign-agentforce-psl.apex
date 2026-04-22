// Atribui a PSL "Agentforce (Default)" (EinsteinGPTCopilotPsl) aos users colaboradores
// para que o Employee Agent apareca no LEX deles.

List<String> usernames = new List<String>{
    'marina.colaboradora@itau.demo.00dhp00000kp228.local',
    'pedro.colaborador@itau.demo.00dhp00000kp228.local',
    'carlos.gestor@itau.demo.00dhp00000kp228.local'
};

PermissionSetLicense psl = [
    SELECT Id, DeveloperName, MasterLabel, TotalLicenses, UsedLicenses
    FROM PermissionSetLicense
    WHERE DeveloperName = 'EinsteinGPTCopilotPsl' LIMIT 1
];
System.debug('=== PSL: ' + psl.MasterLabel + ' | Used=' + psl.UsedLicenses + '/' + psl.TotalLicenses);

List<User> users = [SELECT Id, Username, Name FROM User WHERE Username IN :usernames];

Set<Id> userIds = new Set<Id>();
for (User u : users) userIds.add(u.Id);

Map<Id, Id> existingAssigns = new Map<Id, Id>();
for (PermissionSetLicenseAssign a : [
        SELECT Id, AssigneeId FROM PermissionSetLicenseAssign
        WHERE PermissionSetLicenseId = :psl.Id AND AssigneeId IN :userIds]) {
    existingAssigns.put(a.AssigneeId, a.Id);
}

List<PermissionSetLicenseAssign> toInsert = new List<PermissionSetLicenseAssign>();
for (User u : users) {
    if (existingAssigns.containsKey(u.Id)) {
        System.debug('  SKIP (ja atribuido): ' + u.Name);
    } else {
        toInsert.add(new PermissionSetLicenseAssign(AssigneeId = u.Id, PermissionSetLicenseId = psl.Id));
        System.debug('  WILL ASSIGN: ' + u.Name);
    }
}

if (!toInsert.isEmpty()) {
    Database.SaveResult[] results = Database.insert(toInsert, false);
    for (Integer i = 0; i < results.size(); i++) {
        Database.SaveResult r = results[i];
        if (r.isSuccess()) {
            System.debug('  OK: ' + users[i].Name);
        } else {
            System.debug('  FAIL: ' + users[i].Name + ' -> ' + r.getErrors()[0].getMessage());
        }
    }
} else {
    System.debug('Nada a atribuir.');
}
