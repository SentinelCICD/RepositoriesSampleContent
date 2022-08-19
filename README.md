# Sample Content Repository
This repository provides examples on how to use parameter file with CI/CD feature. For questions and feedback, please contact [SentinelEcoDevs@microsoft.com](SentinelEcoDevs@microsoft.com) 

*Please note* that this repository contains sample content that is not intended to be used as or in the place of any real security content. The sole intention of this repository is to help demonstrate the capabilities of Microsoft Sentinel Repositories.

# Sentinel Deployment Configuration
The file sentinel-deployment.config is located at the root folder in the repository, it may contain three sections to deploy a list of content files in advace, exclude some content files, and map a content file to a parameter file. All paths in the configuration file are full paths from the root directory.
1. prioritizedcontentfiles: a list of content files that would be deployed before the script traverse the entire repository for ARM templates.
2. excludecontentfiles: a list of content files wouldn't be deployed.
3. parameterfilemappings: a map to link a parameter file with a content file.

* Configuration sample:
    {
      "prioritizedcontentfiles": [
        "parsers/Sample/ASimAuthenticationAWSCloudTrail.json",
        "workbooks/sample/TrendMicroDeepSecurityAttackActivity_ARM.json",
        "Playbooks/PaloAlto-PAN-OS/PaloAltoCustomConnector/azuredeploy.json"
      ], 
      "excludecontentfiles": [
         "Detections/Sample/PaloAlto-PortScanning.json",
         "parameters"
      ],
      "parameterfilemappings": {
        "879001c8-2181-4374-be7d-72e5dc69bd2b": {
          "Playbooks/PaloAlto-PAN-OS/Playbooks/PaloAlto-PAN-OS-BlockIP/azuredeploy.json": "parameters/samples/parameter-file-1.json"
        },
        "9af71571-7181-4cef-992e-ef3f61506b4e": {
          "Playbooks/Enrich-SentinelIncident-GreyNoiseCommunity-IP/azuredeploy.json": "path/to/any-parameter-file.json"
        }
      },
      "DummySection": "This shouldn't impact deployment"
    }

# Parameter File Location 
There are three types of parameter file:
1. Mapped parameter file: the file path is specified in the deployment configuration.
2. Workspace specific parameter file: the parameter file is named "<azurearmtemplate>.parameters-<workspaceId>.json", at the same folder as the content file "<azurearmtemplate>.json".
3. Default specific parameter file: the parameter file is named "<azurearmtemplate>.parameters.json", at the same folder as the content file "<azurearmtemplate>.json".

**Parameter file precedence**: The script priortizes paramter files based on the following order: 
mapped parameter file > workspace specific parameter file > default parameter file 

This means that if your repository has a specified parameter file mapping, it will use that as opposed to any workspace specific parameter file or any default parameter file found in the content file. 
