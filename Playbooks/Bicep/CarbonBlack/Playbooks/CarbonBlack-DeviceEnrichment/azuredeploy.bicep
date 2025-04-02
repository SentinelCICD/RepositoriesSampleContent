metadata title = 'Endpoint enrichment - Carbon Black'
metadata description = 'This playbook will collect device information from Carbon Black and post a report on the incident.'
metadata prerequisites = [
  '1. CarbonBlack Custom Connector needs to be deployed prior to the deployment of this playbook under the same resource group.'
  '2. Generate an API key. Refer this link [ how to generate the API Key](https://developer.carbonblack.com/reference/carbon-black-cloud/authentication/#creating-an-api-key)'
  '3. [Find Organziation key](https://developer.carbonblack.com/reference/carbon-black-cloud/authentication/#creating-an-api-key)'
]
metadata prerequisitesDeployTemplateFile = '../../CarbonBlackConnector/azuredeploy.json'
metadata lastUpdateTime = '2021-07-28T00:00:00.000Z'
metadata entities = [
  'Host'
]
metadata tags = [
  'Enrichment'
]
metadata support = {
  tier: 'community'
}
metadata author = {
  name: 'Accenture'
}

@description('Name of the Logic Apps resource to be created')
param PlaybookName string = 'EndpointEnrichment-CarbonBlack'

@description('Name of the custom connector which interacts with Carbon Black')
param CustomConnectorName string = 'CarbonBlackCloudConnector'

@description('CarbonBlack Org Key')
param OrganizationKey string = 'OrganizationKey'
param workspace string

var AzureSentinelConnectionName = 'azuresentinel-${PlaybookName}'
var CarbonBlackConnectionName = 'CarbonBlackCloudConnector-${PlaybookName}'
var TeamsConnectionName = 'teamsconnector-${PlaybookName}'

resource CarbonBlackConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: CarbonBlackConnectionName
  location: resourceGroup().location
  properties: {
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/customApis/${CustomConnectorName}'
    }
  }
}

resource AzureSentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: AzureSentinelConnectionName
  location: resourceGroup().location
  kind: 'V1'
  properties: {
    displayName: AzureSentinelConnectionName
    customParameterValues: {}
    parameterValueType: 'Alternative'
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azuresentinel'
    }
  }
}

resource Playbook 'Microsoft.Logic/workflows@2017-07-01' = {
  name: PlaybookName
  location: resourceGroup().location
  tags: {
    'hidden-SentinelTemplateName': 'EndpointEnrichment-CarbonBlack'
    'hidden-SentinelTemplateVersion': '1.0'
  }
  identity: {
    type: 'SystemAssigned'
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
        'When_Azure_Sentinel_incident_creation_rule_was_triggered_(Private_Preview_only)': {
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
        'Add_comment_to_incident_(V3)': {
          runAfter: {
            Compose: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              incidentArmId: '@triggerBody()?[\'object\']?[\'id\']'
              message: '<p>@{outputs(\'Compose\')} &nbsp;<span style="font-size: 16px"><strong>CarbonBlack DeviceEnrichment Playbook<br>\n</strong></span><span style="font-size: 16px">CarbonBlack DeviceEnrichment playbook was triggered and collected the following information from Carbon Black:<br>\n<br>\n</span><span style="font-size: 16px">@{body(\'Create_HTML_table_to_format_the_results_returned\')}</span><span style="font-size: 16px"></span></p>'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/Incidents/Comment'
          }
        }
        Append_Hosts_list: {
          runAfter: {
            'Entities_-_Get_Hosts': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'HostsList'
                type: 'array'
                value: []
              }
            ]
          }
          description: 'Variable to append all the hosts returned from provider'
        }
        Compose: {
          runAfter: {
            Create_HTML_table_to_format_the_results_returned: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '<img src="https://avatars.githubusercontent.com/u/2071378?s=280&v=4" alt="Lamp" width="32" height="32">'
        }
        Create_HTML_table_to_format_the_results_returned: {
          runAfter: {
            Search_devices_in_your_organization: [
              'Succeeded'
            ]
          }
          type: 'Table'
          inputs: {
            columns: [
              {
                header: 'Devicename'
                value: '@item()?[\'name\']'
              }
              {
                header: 'Quarantined'
                value: '@item()?[\'quarantined\']'
              }
              {
                header: 'Policyname'
                value: '@item()?[\'policy_name\']'
              }
              {
                header: 'PolicyId'
                value: '@item()?[\'policy_id\']'
              }
              {
                header: 'DeviceownerId'
                value: '@item()?[\'device_owner_id\']'
              }
              {
                header: 'DeviceId'
                value: '@item()?[\'id\']'
              }
              {
                header: 'Devicestatus'
                value: '@item()?[\'status\']'
              }
              {
                header: 'Operatingsystem'
                value: '@item()?[\'os\']'
              }
              {
                header: 'OperatingsystemVersion'
                value: '@item()?[\'os_version\']'
              }
              {
                header: 'Organizationname'
                value: '@item()?[\'organization_name\']'
              }
              {
                header: 'Email'
                value: '@item()?[\'email\']'
              }
              {
                header: 'Sensorstates'
                value: '@join(item()?[\'sensor_states\'],\',\')'
              }
              {
                header: 'LastreportedTime'
                value: '@item()?[\'last_reported_time\']'
              }
              {
                header: 'SensorVersion'
                value: '@{item()?[\'sensor_version\']}'
              }
            ]
            format: 'HTML'
            from: '@body(\'Search_devices_in_your_organization\')?[\'results\']'
          }
          description: 'Format the device information'
        }
        'Entities_-_Get_Hosts': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: '@triggerBody()?[\'object\']?[\'properties\']?[\'relatedEntities\']'
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuresentinel\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/entities/host'
          }
        }
        For_each_Hosts: {
          foreach: '@body(\'Entities_-_Get_Hosts\')?[\'Hosts\']'
          actions: {
            Append_hosts_to_format_the_Lucense_query: {
              runAfter: {}
              type: 'AppendToArrayVariable'
              inputs: {
                name: 'HostsList'
                value: 'name : @{items(\'For_each_Hosts\')?[\'HostName\']}'
              }
            }
          }
          runAfter: {
            Organization_Id: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
          description: 'Iterate over hosts returned from provider'
        }
        Join_Hosts_with_OR_operator: {
          runAfter: {
            For_each_Hosts: [
              'Succeeded'
            ]
          }
          type: 'Join'
          inputs: {
            from: '@variables(\'HostsList\')'
            joinWith: ' OR '
          }
          description: 'Format the Lucense query to pass as a parameter to the search organizations in your organization'
        }
        Organization_Id: {
          runAfter: {
            Append_Hosts_list: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'OrganizationKey'
                type: 'string'
                value: OrganizationKey
              }
            ]
          }
          description: 'Configured Organization Id'
        }
        Search_devices_in_your_organization: {
          runAfter: {
            Join_Hosts_with_OR_operator: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              query: '@body(\'Join_Hosts_with_OR_operator\')'
            }
            headers: {
              'Content-Type': 'application/json'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'CarbonBlackCloudConnector\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/appservices/v6/orgs/@{encodeURIComponent(variables(\'OrganizationKey\'))}/devices/_search'
          }
          description: 'Search devices in organization by providing filter criteria'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          CarbonBlackCloudConnector: {
            connectionId: CarbonBlackConnection.id
            connectionName: CarbonBlackConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/customApis/${CustomConnectorName}'
          }
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
        }
      }
    }
  }
}
