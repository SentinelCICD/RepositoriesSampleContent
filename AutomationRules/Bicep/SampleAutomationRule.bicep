param workspace string

resource workspace_Microsoft_SecurityInsights_85f2eac9_43f1_480e_b8ad_473375c195c0 'Microsoft.OperationalInsights/workspaces/providers/automationRules@2019-01-01-preview' = {
  name: '${workspace}/Microsoft.SecurityInsights/85f2eac9-43f1-480e-b8ad-473375c195c1'
  kind: 'Scheduled'
  properties: {
    displayName: 'Repositories automation rule 1'
    order: 1
    triggeringLogic: {
      isEnabled: true
      expirationTimeUtc: null
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: [
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentTactics'
            operator: 'Contains'
            propertyValues: [
              'Persistence'
            ]
          }
        }
      ]
    }
    actions: [
      {
        order: 1
        actionType: 'ModifyProperties'
        actionConfiguration: {
          owner: {
            objectId: 'b18ef471-be11-439d-9279-5ce4e18b976e'
            email: 'SampleEmail@Contoso.com'
            userPrincipalName: 'SampleUser@Contoso.com'
          }
        }
      }
    ]
  }
}
