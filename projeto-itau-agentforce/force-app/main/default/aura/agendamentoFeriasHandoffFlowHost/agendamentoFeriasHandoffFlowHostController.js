({
    init: function (component, event, helper) {
        var flow = component.find("flowData");
        var inputVariables = [
            {
                name: "varAgentId",
                type: "String",
                value: component.get("v.varAgentId")
            }
        ];
        flow.startFlow("Agendamento_Ferias_Handoff_Screen", inputVariables);
    }
})
