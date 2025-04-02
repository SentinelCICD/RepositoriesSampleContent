@description('Name of the custom connector')
param CarbonBlack_CustomConnector_Name string = 'CarbonBlackConnector'

@description('enter the Carbon Black base URL (ex: https://defense.conferdeploy.net)')
param Service_EndPoint string = 'https://{CarbonblackBaseURL}'

@description('Name of the Playbook')
param CarbonBlack_TakeDeviceActionFromTeams_Playbook_Name string = 'CarbonBlack-TakeDeviceActionFromTeams'

@description('Name of the Playbook')
param CarbonBlack_DeviceEnrichment_Playbook_Name string = 'CarbonBlack-DeviceEnrichment'

@description('Name of the Playbook')
param CarbonBlack_QuarantineDevice_Playbook_Name string = 'CarbonBlack-QuarantineDevice'

@description('Carbon Black Org Key')
param OrganizationKey string = 'OrganizationKey'

@description('(Optional: can be configured in the playbook) For playbook which allows update policy, supply the policy ID from Carbon Black')
param PolicyId int = 0

@description('(Optional: can be configured in the playbook) For playbook which sends an adaptive card to response from Teams. This is the Group ID of the Team channel')
param Teams_GroupId string = 'Teams_GroupId'

@description('(Optional: can be configured in the playbook) For playbook which sends an adaptive card to response from Teams. This is the Channel ID of the Team channel')
param Teams_ChannelId string = 'Teams_ChannelId'
param workspace string

module CarbonBlack_Customconnector_LinkedTemplate 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Playbooks/CarbonBlack/CarbonBlackConnector/azuredeploy.json' = {
  name: 'CarbonBlack_Customconnector_LinkedTemplate'
  params: {
    CustomConnectorName: CarbonBlack_CustomConnector_Name
    'Service EndPoint': Service_EndPoint
  }
}

module CarbonBlack_TakeDeviceActionFromTeams_LinkedTemplate 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Playbooks/CarbonBlack/Playbooks/CarbonBlack-TakeDeviceActionFromTeams/azuredeploy.json' = {
  name: 'CarbonBlack-TakeDeviceActionFromTeams_LinkedTemplate'
  params: {
    PlaybookName: CarbonBlack_TakeDeviceActionFromTeams_Playbook_Name
    CustomConnectorName: CarbonBlack_CustomConnector_Name
    OrganizationKey: OrganizationKey
    PolicyId: PolicyId
    'Teams GroupId': Teams_GroupId
    'Teams ChannelId': Teams_ChannelId
  }
  dependsOn: [
    CarbonBlack_Customconnector_LinkedTemplate
  ]
}

module CarbonBlack_DeviceEnrichment_LinkedTemplate 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Playbooks/CarbonBlack/Playbooks/CarbonBlack-DeviceEnrichment/azuredeploy.json' = {
  name: 'CarbonBlack-DeviceEnrichment_LinkedTemplate'
  params: {
    PlaybookName: CarbonBlack_DeviceEnrichment_Playbook_Name
    CustomConnectorName: CarbonBlack_CustomConnector_Name
    OrganizationKey: OrganizationKey
  }
  dependsOn: [
    CarbonBlack_Customconnector_LinkedTemplate
  ]
}

module CarbonBlack_QuarantineDevice_LinkedTemplate 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Playbooks/CarbonBlack/Playbooks/CarbonBlack-QuarantineDevice/azuredeploy.json' = {
  name: 'CarbonBlack-QuarantineDevice_LinkedTemplate'
  params: {
    PlaybookName: CarbonBlack_QuarantineDevice_Playbook_Name
    CustomConnectorName: CarbonBlack_CustomConnector_Name
    OrganizationKey: OrganizationKey
  }
  dependsOn: [
    CarbonBlack_Customconnector_LinkedTemplate
  ]
}
