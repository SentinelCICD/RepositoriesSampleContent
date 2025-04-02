param workspace string

resource workspace_ASimAuthenticationAWSCloudTrail 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  name: '${workspace}/ASimAuthenticationAWSCloudTrail'
  location: resourceGroup().location
  properties: {
    etag: '*'
    displayName: 'ASIM AWS authentication'
    category: 'Security'
    functionAlias: 'ASimAuthenticationAWSCloudTrail'
    query: 'let AWSLogon=(disabled:bool=false){\nAWSCloudTrail | where not(disabled)\n | where EventName == \'ConsoleLogin\'\n | extend\n  EventVendor = \'AWS\'\n  , EventProduct=\'AWSCloudTrail\'\n  , EventCount=int(1)\n  , EventSchemaVersion=\'0.1.0\'\n  , EventResult= iff (ResponseElements has_cs \'Success\', \'Success\', \'Failure\')\n  , EventStartTime=TimeGenerated\n  , EventEndTime=TimeGenerated\n  , EventType=\'Logon\'\n  , LogonMethod=iff(AdditionalEventData has \'"MFAUsed": "No"\', \'NoMFA\', \'MFA\')\n  , TargetUrl =tostring(todynamic(AdditionalEventData).LoginTo)\n  , TargetUsernameType=\'Simple\'\n  , TargetUserIdType=\'AWSId\'\n  | project-rename\n    EventOriginalUid= AwsEventId\n  , EventOriginalResultDetails= ErrorMessage\n  , TargetUsername= UserIdentityUserName\n  , TargetUserType=UserIdentityType\n  , TargetUserId=UserIdentityAccountId \n  , SrcDvcIpAddr=SourceIpAddress\n  , HttpUserAgent=UserAgent\n// **** Aliases\n| extend\n       User=TargetUsername\n      , LogonTarget=tostring(split(TargetUrl,\'?\')[0])\n      , Dvc=EventVendor\n  };\n  AWSLogon(disabled)\n'
    version: 1
    functionParameters: 'disabled:bool=False'
  }
}
