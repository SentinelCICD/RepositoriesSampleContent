# Sample Content Repository
This repository provides samples of deployable Sentinel content as well as examples on how to use parameter files with the Sentinel Repositories CI/CD feature to help scale your deployments. For questions and feedback, please contact [SentinelEcoDevs@microsoft.com](SentinelEcoDevs@microsoft.com) 

**Please note** that this repository contains sample content that is not intended to be used as or in the place of any real security content. The sole intention of this repository is to help demonstrate the capabilities of Microsoft Sentinel Repositories.

# The Sample Content Folders
You can find a variety of supported content to use in your test deployments in the respective content folders of this repository. In addition, you can utilize the JSON or YAML to ARM scripts we've included in some folders (e.g. Detections, Hunting, and Workbooks) to convert your content files to the supported ARM format for repositories deployment. Please note that these scripts were used to convert some of the content in the [Azure Sentinel Community Repository](https://github.com/Azure/Azure-Sentinel) but have not been tested on all variations of content, please use with care.

# Scaling your CICD pipeline
## Sentinel Deployment Configuration
To further customize your CICD pipeline beyond the default settings, you can modify your deployment workflow or utilize a configuration file to tailor your the pipeline to your specific needs - more on this in [the documentation](https://learn.microsoft.com/en-us/azure/sentinel/ci-cd-custom-deploy?tabs=github). 
The file sentinel-deployment.config is located at the root folder in the repository, it may contain three sections to deploy a list of content files in advance, exclude some content files, and map content files to parameter files within the repository. All paths in the configuration file are full paths from the root directory.
1. prioritizedcontentfiles: a list of content files that would be deployed before the script traverses the entire repository for ARM templates.
2. excludecontentfiles: a list of content files wouldn't be deployed regardless of their type.
3. parameterfilemappings: a map to link a parameter file with a content file in the repository.

* Configuration sample:
```
{
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
}
```

## Parameter File usage
Parameter files allow you to use a JSON file that contains the parameter values instead of passing the parameters as inline values in each of your content files. The general naming convention for the parameter file is to include parameters in the template name. For example, if your content file template is named PlaybookABC.json, your parameter file is named PlaybookABCparameters.json. 

We've created three ways to pair your parameter files to your content files based on the above recommendation:
1. Explicitly Mapped parameter files: the file path is specified in the deployment configuration. This mapping pairs up any parameter files with their corresponding content files. 
2. Workspace specific parameter file: the parameter file is named "<azurearmtemplate>.parameters-<workspaceId>.json", at the same folder as the content file "<azurearmtemplate>.json". Your workspace ID can be used to here to allow the script to pair your parameter file(s) to your connected workspace. 
3. Default specific parameter file: the parameter file is named "<azurearmtemplate>.parameters.json", at the same folder as the content file "<azurearmtemplate>.json". If neither of the two above mapping mechanisms are used, this would be the default and allows for parameter files to be automatically paired with whatever content files are present in the same folder.

**Parameter file precedence**: The script prioritizes paramater files based on the following order: 
mapped parameter file > workspace specific parameter file > default parameter file 

This means that if your repository has a specified parameter file mapping, it will use that as opposed to any workspace specific parameter file or any default parameter file found in the content file's folder.  

![image](https://user-images.githubusercontent.com/66967658/194126802-24b1c47e-2ab4-48cf-bcaf-50b48dde2cd2.png)

