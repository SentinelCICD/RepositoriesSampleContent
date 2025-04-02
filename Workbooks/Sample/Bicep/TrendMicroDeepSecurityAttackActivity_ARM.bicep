param workspace string

@description('Appended to workbook displayNames to make them unique')
param formattedTimeNow string = utcNow('g')

@description('Unique id for the workbook')
@minLength(1)
param workbook_id string = '63ee0341-8776-4ff7-8ba7-0a9915b5ee69'

@description('Name for the workbook')
@minLength(1)
param workbook_name string = 'TrendMicroDeepSecurityAttackActivity'

resource workbook_id_resource 'Microsoft.Insights/workbooks@2020-02-12' = {
  name: workbook_id
  location: resourceGroup().location
  kind: 'shared'
  properties: {
    displayName: '${workbook_name} - ${formattedTimeNow}'
    serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## Trend Micro Deep Security ATT&CK Related Activity"},"name":"text - 2"},{"type":9,"content":{"version":"KqlParameterItem/1.0","parameters":[{"id":"94910267-b8f6-4b30-aa2f-e5780ad9738e","version":"KqlParameterItem/1.0","name":"TimeRange","type":4,"isRequired":true,"value":{"durationMs":604800000},"typeSettings":{"selectableValues":[{"durationMs":300000},{"durationMs":900000},{"durationMs":1800000},{"durationMs":3600000},{"durationMs":14400000},{"durationMs":43200000},{"durationMs":86400000},{"durationMs":172800000},{"durationMs":259200000},{"durationMs":604800000},{"durationMs":1209600000}],"allowCustom":false}}],"style":"pills","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"name":"parameters - 1"},{"type":1,"content":{"json":"---"},"name":"text - 29"},{"type":3,"content":{"version":"KqlItem/1.0","query":"TrendMicroDeepSecurity\\r\\n| where Activity contains \\"ATT&CK\\"\\r\\n| summarize count() by DeepSecurityModuleName, bin(TimeGenerated, 1h)","size":3,"exportFieldName":"SelectedDeviceAction","exportParameterName":"SelectedDeviceAction","exportDefaultValue":"All","exportToExcelOptions":"visible","title":"ATT&CK Event History","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"categoricalbar","tileSettings":{"titleContent":{"columnMatch":"SimplifiedDeviceAction","formatter":1,"formatOptions":{"showIcon":true}},"leftContent":{"columnMatch":"Count","formatter":12,"formatOptions":{"palette":"auto","showIcon":true},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"secondaryContent":{"columnMatch":"Trend","formatter":9,"formatOptions":{"showIcon":true}},"showBorder":false},"chartSettings":{"showLegend":true}},"name":"ATT&CK Event History"},{"type":3,"content":{"version":"KqlItem/1.0","query":"TrendMicroDeepSecurity\\n| where Activity contains \\"ATT&CK\\"\\n| summarize Count=count() by Activity = strcat(DeepSecurityModuleName,\\" - \\",Activity)\\n| top 10 by Count","size":0,"exportToExcelOptions":"visible","title":"Top ATT&CK Events","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"customWidth":"50","name":"Top ATT&CK Events","styleSettings":{"maxWidth":"50"}},{"type":3,"content":{"version":"KqlItem/1.0","query":"TrendMicroDeepSecurity\\n| where Activity contains \\"ATT&CK\\"\\n| summarize Count=count() by Host=DeviceName\\n| top 10 by Count","size":0,"exportToExcelOptions":"visible","title":"Top ATT&CK Computers","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"customWidth":"50","name":"Top ATT&CK Computers","styleSettings":{"maxWidth":"50"}}],"fromTemplateId":"sentinel-TrendMicroAttackActivity","$schema":"https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"}\r\n'
    version: '1.0'
    sourceId: '${resourceGroup().id}/providers/Microsoft.OperationalInsights/workspaces/${workspace}'
    category: 'sentinel'
    etag: '*'
  }
}
