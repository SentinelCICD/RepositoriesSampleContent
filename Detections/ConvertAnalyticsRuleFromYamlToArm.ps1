$jsonConversionDepth = 50
function checkISO8601Format($field) {
    if ($field.IndexOf("D") -ne -1) {
        return "P$field"
    }
    else {
        "PT$field"
    }
}
function ConvertAnalyticsRuleFromYamlToArm {
    param (
        # Parameter help description
        [Parameter(Mandatory)][string] $inputFilePath,
        [Parameter(Mandatory)][string] $outputFilePath
    )

    $file = Get-Item -Path $inputFilePath
    $yaml = $null
    if ($file.FullName -match "(\.yaml)$") {
        $rawData = Get-Content $inputFilePath
        $content = ''
        foreach ($line in $rawData) {
            $content = $content + "`n" + $line
        }

        try {
            $yaml = ConvertFrom-YAML $content
        }
        catch {
            Write-Host "Failed to deserialize $file $_" -ForegroundColor Red 
            break;
        }               
    }
                            
    $basicJson =
    @"
{                        
    "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspace": {
            "type": "String"
        }
    },
    "resources":[]
}
"@

    $baseMainTemplate = ConvertFrom-Json $basicJson

    $ruleId = New-Guid
    $yamlPropertiesToCopyFrom = "name", "severity", "triggerThreshold", "query"
    $yamlPropertiesToCopyTo = "displayName", "severity", "triggerThreshold", "query"
    $alertRuleParameterName = "analytic-id"
    $alertRule = [PSCustomObject] @{ description = ""; displayName = ""; enabled = $false; query = ""; queryFrequency = ""; queryPeriod = ""; severity = ""; suppressionDuration = ""; suppressionEnabled = $false; triggerOperator = ""; triggerThreshold = 0; }
    $alertRuleParameter = [PSCustomObject] @{ type = "string"; defaultValue = "$ruleId"; minLength = 1; metadata = [PSCustomObject] @{ description = "Unique id for the scheduled alert rule" }; }

    # Copy all directly transposable properties
    foreach ($yamlProperty in $yamlPropertiesToCopyFrom) {
        $index = $yamlPropertiesToCopyFrom.IndexOf($yamlProperty)
        $alertRule.$($yamlPropertiesToCopyTo[$index]) = $yaml.$yamlProperty
    }
    if (!$yaml.severity) {
        $alertRule.severity = "Medium"
    }
                                                        
    # Content Modifications
    $triggerOperators = [PSCustomObject] @{ gt = "GreaterThan" ; lt = "LessThan" ; eq = "Equal" ; ne = "NotEqual" }
    $alertRule.triggerOperator = $triggerOperators.$($yaml.triggerOperator)
    if ($yaml.tactics -and ($yaml.tactics.Count -gt 0) ) {
        if ($yaml.tactics -match ' ') {
            $yaml.tactics = $yaml.tactics -replace ' ', ''
        }
        $alertRule | Add-Member -NotePropertyName tactics -NotePropertyValue $yaml.tactics # Add Tactics property if exists
    }
    $alertRule.description = $yaml.description.TrimEnd() #remove newlines at the end of the string if there are any.
    if ($alertRule.description.StartsWith("'") -or $alertRule.description.StartsWith('"')) {
        # Remove surrounding single-quotes (') from YAML block literal string, in case the string starts with a single quote in Yaml.
        # This block is for backwards compatibility as YAML doesn't require having strings quotes by single (or double) quotes
        $alertRule.description = $alertRule.description.substring(1, $alertRule.description.length - 2)
    }
    
    # Check whether Day or Hour/Minut format need be used
    $alertRule.queryFrequency = $(checkISO8601Format $yaml.queryFrequency.ToUpper())
    $alertRule.queryPeriod = $(checkISO8601Format $yaml.queryPeriod.ToUpper())
    $alertRule.suppressionDuration = "PT1H"
    
    # Create Alert Rule Resource Object
    $newAnalyticRule = [PSCustomObject]@{
        type       = "Microsoft.OperationalInsights/workspaces/providers/alertRules";
        name       = "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/',parameters('analytic$analyticRuleCounter-id'))]";
        apiVersion = "2020-01-01";
        kind       = "Scheduled";
        location   = "[resourceGroup().location]";
        properties = $alertRule;
    }
    
    # Add Resource and Parameters to Template
    $baseMainTemplate.resources = @()
    $baseMainTemplate.resources += $newAnalyticRule
    $baseMainTemplate.parameters | Add-Member -MemberType NoteProperty -Name $alertRuleParameterName -Value $alertRuleParameter
         

    ConvertTo-Json $baseMainTemplate -EscapeHandling Default -Depth $jsonConversionDepth  | Set-Content -Path $outputFilePath
}
