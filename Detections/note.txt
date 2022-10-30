Install-Module PowerShell-yaml
Import-Module .\ConvertAnalyticsRuleFromYamlToArm.ps1

$newDirectory = New-Item -ItemType Directory -Path ".\Sample"
foreach($parserYaml in $(Get-Item ***\*.yaml))
{
     $outputFilePath = "$($newDirectory.FullName)\$($parserYaml.BaseName).json"
     ConvertAnalyticsRuleFromYamlToArm $parserYaml.FullName $outputFilePath
}
