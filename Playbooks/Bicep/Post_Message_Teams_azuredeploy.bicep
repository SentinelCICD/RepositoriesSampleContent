metadata comments = 'This playbook will Post message on Microsoft Teams channel when incident created.'
metadata author = 'Yaniv Shasha'

param PlaybookName string = 'Post-Message-Teams'
param UserName string = '<username>@<domain>'
param workspace string

var AzureSentinelConnectionName = 'azuresentinel-${PlaybookName}'
var TeamsConnectionName = 'teams-${PlaybookName}'

resource AzureSentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: AzureSentinelConnectionName
  location: resourceGroup().location
  properties: {
    displayName: UserName
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
    }
  }
}

resource TeamsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: TeamsConnectionName
  location: resourceGroup().location
  properties: {
    displayName: UserName
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/teams'
    }
  }
}

resource Playbook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: PlaybookName
  location: resourceGroup().location
  tags: {
    LogicAppsCategory: 'security'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_response_to_an_Azure_Sentinel_alert_is_triggered: {
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              callback_url: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            path: '/subscribe'
          }
        }
      }
      actions: {
        'Alert_-_Get_incident': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/Cases/@{encodeURIComponent(triggerBody()?[\'SystemAlertId\'])}/@{encodeURIComponent(triggerBody()?[\'WorkspaceSubscriptionId\'])}/@{encodeURIComponent(triggerBody()?[\'WorkspaceId\'])}/@{encodeURIComponent(triggerBody()?[\'WorkspaceResourceGroup\'])}'
          }
        }
        'Post_a_message_(V3)': {
          runAfter: {
            'Alert_-_Get_incident': [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              body: {
                content: '<p>Severity of Alert: @{triggerBody()?[\'Severity\']}<br>\n<br>\nAzure Sentinel Alert; <br>\nTItle: @{body(\'Alert_-_Get_incident\')?[\'properties\']?[\'Title\']}<br>\nStatus: @{body(\'Alert_-_Get_incident\')?[\'properties\']?[\'Status\']}<br>\nNumber: @{body(\'Alert_-_Get_incident\')?[\'properties\']?[\'CaseNumber\']}<br>\nCreated Time (UTC): @{body(\'Alert_-_Get_incident\')?[\'properties\']?[\'CreatedTimeUtc\']}<br>\n<br>\nAlert Details:<br>\nAlert Display Name: @{triggerBody()?[\'AlertDisplayName\']}<br>\nAlert Type: @{triggerBody()?[\'AlertType\']}<br>\nSubscription ID: @{triggerBody()?[\'WorkspaceSubscriptionId\']}<br>\nProvider Alert ID: @{triggerBody()?[\'ProviderAlertId\']}<br>\nExtneded Links: @{triggerBody()?[\'ExtendedLinks\']}</p>'
                contentType: 'html'
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'teams\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v3/beta/teams/@{encodeURIComponent(\'d05ba55c-593e-4bfa-8011-26e0626b5c14\')}/channels/@{encodeURIComponent(\'19:8e52aee721394ab78563596463c067dc@thread.skype\')}/messages'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: AzureSentinelConnection.id
            connectionName: AzureSentinelConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
          }
          teams: {
            connectionId: TeamsConnection.id
            connectionName: TeamsConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/teams'
          }
        }
      }
    }
  }
}
