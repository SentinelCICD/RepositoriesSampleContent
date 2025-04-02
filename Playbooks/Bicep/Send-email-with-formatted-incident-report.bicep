metadata title = 'Send email with formatted incident report'
metadata description = 'This playbook will be sending email with formated incidents report (Incident title, severity, tactics, link,…) when incident is created in Azure Sentinel. Email notification is made in HTML.'
metadata prerequisites = 'An O365 account to be used to send email notification (The user account will be used in O365 connector (Send an email).) Link with company logo. No formating since size is defined in the Playbook. Linke example - https://azure.microsoft.com/svghandler/azure-sentinel'
metadata lastUpdateTime = '2021-07-14T00:00:00.000Z'
metadata entities = []
metadata tags = [
  'Notification'
]
metadata support = {
  tier: 'community'
}
metadata author = {
  name: 'Benjamin Kovacevic'
}

param PlaybookName string = 'Send-email-with-formatted-incident-report'

@description('Incident details will be sent to this email (ex. soc@xyz.com)')
param NotificationEmail string = 'abc@contoso.com'

@description('Company logo that will be visible in the incident report (size defined in template) (ex. https://azure.microsoft.com/svghandler/azure-sentinel)')
param Company_logo_link string = 'https://azure.microsoft.com/svghandler/azure-sentinel'

@description('Company name that will be visible in the report, you can also add SOC (ex. Contoso SOC)')
param Company_name string = 'Contoso SOC'
param workspace string

var AzureSentinelConnectionName = 'azuresentinel-${PlaybookName}'
var o365ConnectionName = 'o365-${PlaybookName}'

resource AzureSentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: AzureSentinelConnectionName
  location: resourceGroup().location
  properties: {
    displayName: PlaybookName
    customParameterValues: {}
    parameterValueType: 'Alternative'
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
    }
  }
}

resource o365Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: o365ConnectionName
  location: resourceGroup().location
  properties: {
    displayName: PlaybookName
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/office365'
    }
  }
}

resource Playbook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: PlaybookName
  location: resourceGroup().location
  tags: {
    'hidden-SentinelTemplateName': 'Send-email-with-formatted-incident-report'
    'hidden-SentinelTemplateVersion': '1.0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
        'Company logo link': {
          defaultValue: Company_logo_link
          type: 'String'
        }
        'Report name': {
          defaultValue: Company_name
          type: 'String'
        }
      }
      triggers: {
        When_Azure_Sentinel_incident_creation_rule_was_triggered: {
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
            path: '/incident-creation'
          }
        }
      }
      actions: {
        Compose_Email_response: {
          runAfter: {
            Create_HTML_table_with_Alerts: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '<!DOCTYPE html>\n<html>\n\n<table style="width: 100%; border-collapse: collapse;" border="1" width="100%">\n\n<tbody>\n\n<tr>\n<td style="width: 19%;" align="center" width="19%">\n<strong><img src="https://azure.microsoft.com/svghandler/azure-sentinel?width=150&amp;height=79" alt="" /></strong>\n</td>\n\n<td style="width: 41.1434%;" width="48%">\n<p style="text-align: center;"><span style="font-size: 16pt;"><strong>@{parameters(\'Report name\')}</strong></span></p>\n<p style="text-align: center;"><strong>Azure Sentinel incident report</strong></p>\n</td>\n\n<td style="width: 20%;" width="20%">\n<p><span style="font-size: 12pt;"><strong>Incident ID: @{triggerBody()?[\'object\']?[\'properties\']?[\'incidentNumber\']}</strong></span></p>\n<p><span style="font-size: 13pt;"><strong><a href="@{triggerBody()?[\'object\']?[\'properties\']?[\'incidentUrl\']}">View incident</a></strong></span></p>\n</td>\n\n<td style="width: 13%;" align="center" width="13%">\n<strong><img src="@{parameters(\'Company logo link\')}?width=150&amp;height=79" alt="" /></strong>\n</td>\n\n</tr>\n\n<tr>\n<td style="width: 93.1434%;" colspan="4" width="100%">\n<p>Incident title:</p>\n<p><span style="font-size: 16pt;"><strong>@{triggerBody()?[\'object\']?[\'properties\']?[\'title\']}</strong></span></p>\n<p>&nbsp;</p>\n</td>\n</tr>\n\n</tbody>\n</table>\n\n<table style="width: 100%; border-collapse: collapse;" border="1" width="100%">\n\n<tbody>\n\n<tr style="vertical-align: top;">\n<td style="width: 23.25%; height: 190px;">\n<p><span style="font-size: 12pt;"><strong>Creation time</strong></span><br /><br/>\n<span style="font-size: 12.0pt;">@{triggerBody()?[\'object\']?[\'properties\']?[\'createdTimeUtc\']}</span></p>\n</td>\n\n<td style="width: 23.25%; height: 190px;">\n<p><span style="font-size: 12pt;"><strong>Severity</strong></span><br /><br/>\n<span style="font-size: 12.0pt;">@{triggerBody()?[\'object\']?[\'properties\']?[\'severity\']}</span></p>\n</td>\n\n<td style="width: 23.3934%; height: 190px;">\n<p><span style="font-size: 12pt;"><strong>Alert providers</strong></span><br /><br/>\n<span style="font-size: 12.0pt;">@{join(triggerBody()?[\'object\']?[\'properties\']?[\'additionalData\']?[\'alertProductNames\'], \'<br />\')}</span></p>\n</td>\n\n<td style="width: 23.25%; height: 190px;">\n<p><span style="font-size: 12pt;"><strong>Tactics</strong></span><br /><br/>\n<span style="font-size: 12.0pt;">@{join(triggerBody()?[\'object\']?[\'properties\']?[\'additionalData\']?[\'tactics\'], \'<br />\')}</span></p>\n</td>\n</tr>\n\n<td style="width: 93.1434%;" colspan="4" width="100%">\n<p><span style="font-size: 12pt;"><strong>Description</strong></span><br /><br />\n<span style="font-size: 12.0pt;">@{triggerBody()?[\'object\']?[\'properties\']?[\'description\']}</span></p>\n</td>\n</tr>\n\n<tr>\n<td style="width: 46.5%;" colspan="2" width="50%">\n<p><span style="font-size: 12pt;"><strong>Entities</strong></span></p>\n<p>@{body(\'Create_HTML_table_with_Entities\')}</p>\n<p>&nbsp;</p>\n</td>\n\n<td style="width: 46.6434%;" colspan="2" width="50%">\n@{body(\'Create_HTML_table_with_Alerts\')}\n</td>\n\n</tr>\n\n</tbody>\n</table>\n</html>'
        }
        Create_HTML_table_with_Alerts: {
          runAfter: {
            Select_Alerts: [
              'Succeeded'
            ]
          }
          type: 'Table'
          inputs: {
            format: 'HTML'
            from: '@body(\'Select_Alerts\')'
          }
        }
        Create_HTML_table_with_Entities: {
          runAfter: {
            Select_Entities: [
              'Succeeded'
            ]
          }
          type: 'Table'
          inputs: {
            format: 'HTML'
            from: '@body(\'Select_Entities\')'
          }
        }
        Select_Alerts: {
          runAfter: {
            Create_HTML_table_with_Entities: [
              'Succeeded'
            ]
          }
          type: 'Select'
          inputs: {
            from: '@triggerBody()?[\'object\']?[\'properties\']?[\'Alerts\']'
            select: {
              Alerts: '@item()?[\'properties\']?[\'alertDisplayName\']'
            }
          }
        }
        Select_Entities: {
          runAfter: {}
          type: 'Select'
          inputs: {
            from: '@triggerBody()?[\'object\']?[\'properties\']?[\'relatedEntities\']'
            select: {
              Entity: '@item()?[\'properties\']?[\'friendlyName\']'
              'Entity type': '@item()?[\'kind\']'
            }
          }
        }
        Send_an_email_with_Incident_details: {
          runAfter: {
            Compose_Email_response: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '<p>@{outputs(\'Compose_Email_response\')}</p>'
              Importance: 'High'
              Subject: 'New Azure Sentinel incident - @{triggerBody()?[\'object\']?[\'properties\']?[\'title\']}'
              To: NotificationEmail
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
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
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
          office365: {
            connectionId: o365Connection.id
            connectionName: o365ConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/office365'
          }
        }
      }
    }
  }
}
