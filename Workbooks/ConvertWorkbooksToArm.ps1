
$jsonConversionDepth = 50
function removePropertiesRecursively ($resourceObj) {
    foreach ($prop in $resourceObj.PsObject.Properties) {
        $key = $prop.Name
        $val = $prop.Value
        if ($null -eq $val) {
            $resourceObj.PsObject.Properties.Remove($key)
        }
        elseif ($val -is [System.Object[]]) {
            if ($val.Count -eq 0) {
                $resourceObj.PsObject.Properties.Remove($key)
            }
            else {
                foreach ($item in $val) {
                    $itemIndex = $val.IndexOf($item)
                    $resourceObj.$key[$itemIndex] = $(removePropertiesRecursively $val[$itemIndex])
                }
            }
        }
        else {
            if ($val -is [PSCustomObject]) {
                if ($($val.PsObject.Properties).Count -eq 0) {
                    $resourceObj.PsObject.Properties.Remove($key)
                }
                else {
                    $resourceObj.$key = $(removePropertiesRecursively $val)
                    if ($($resourceObj.$key.PsObject.Properties).Count -eq 0) {
                        $resourceObj.PsObject.Properties.Remove($key)
                    }
                }
            }
        }
    }
    $resourceObj
}

function ConvertWorkbooksToArm {
    param (
        # Parameter help description
        [Parameter(Mandatory)][string] $inputFilePath,
        [Parameter(Mandatory)][string] $outputFilePath
    )

    $file = Get-Item -Path $inputFilePath
    $rawData = Get-Content -Path $inputFilePath
                            
    try {
        # Handle non-ASCII characters (Emoji's)
        $data = $rawData -replace "[^ -~\t]", ""
        # Serialize workbook data
        $serializedData = $data |  ConvertFrom-Json -Depth $jsonConversionDepth
        # Remove empty braces
        $serializedData = $(removePropertiesRecursively $serializedData) | ConvertTo-Json -Compress -Depth $jsonConversionDepth | Out-String
    }
    catch {
        Write-Host "Failed to serialize $file" -ForegroundColor Red
        break;
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

    #Add formattedTimeNow parameter since workbooks exist
    $timeNowParameter = [PSCustomObject]@{
        type         = "string";
        defaultValue = "[utcNow('g')]";
        metadata     = [PSCustomObject]@{
            description = "Appended to workbook displayNames to make them unique";
        }
    }
    $baseMainTemplate.parameters | Add-Member -MemberType NoteProperty -Name "formattedTimeNow" -Value $timeNowParameter

    $workbookId = New-Guid
    $workbookIDParameterName = "workbook-id"
    $workbookNameParameterName = "workbook-name"
    $workbookIDParameter = [PSCustomObject] @{ type = "string"; defaultValue = "$workbookId"; minLength = 1; metadata = [PSCustomObject] @{ description = "Unique id for the workbook" }; }
    $workbookNameParameter = [PSCustomObject] @{ type = "string"; defaultValue = $file.BaseName; minLength = 1; metadata = [PSCustomObject] @{ description = "Name for the workbook" }; }

    # Create Workbook Resource Object
    $newWorkbook = [PSCustomObject]@{
        type       = "Microsoft.Insights/workbooks";
        name       = "[parameters('workbook-id')]";
        location   = "[resourceGroup().location]";
        kind       = "shared";
        apiVersion = "2020-02-12";
        properties = [PSCustomObject] @{
            displayName    = "[concat(parameters('workbook-name'), ' - ', parameters('formattedTimeNow'))]";
            serializedData = $serializedData;
            version        = "1.0";
            sourceId       = "[concat(resourceGroup().id, '/providers/Microsoft.OperationalInsights/workspaces/',parameters('workspace'))]";
            category       = "sentinel"; 
            etag           = "*"
        }
    }

    $baseMainTemplate.resources += $newWorkbook
    $baseMainTemplate.parameters | Add-Member -MemberType NoteProperty -Name $workbookIDParameterName -Value $workbookIDParameter
    $baseMainTemplate.parameters | Add-Member -MemberType NoteProperty -Name $workbookNameParameterName -Value $workbookNameParameter

    ConvertTo-Json $baseMainTemplate -EscapeHandling Default -Depth $jsonConversionDepth  | Set-Content -Path $outputFilePath
}
