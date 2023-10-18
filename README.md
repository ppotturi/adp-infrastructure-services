# ADP Infrastructure Services
This is the ADP Infrastructure Services repository for Platform Services/Tenants. This contains the tenant/service specific infrastructure templates, configurations, and instantiations of common modules.

## Introduction - usage of the ADP Services Repository

| Note: The repository will be supported by an automated onboarding process for Platform Tenants (Services). Please review this documentation with that in mind   |
|:----------|

| Note: More infrastructure is to be added during development, the initial list is just Azure Front Door   |
|:----------|

### Repository Structure

The Platform uses infrastructure parameter files (.bicepParams) to instantiate pre-configured (_by ADP Platform Engineering_) and agnostic infrastructure modules (.bicep templates). If a Service/Tenant cannot use the Azure Service Operator or is not applicable for their scenario, a folder with the associated service will be located here as shown below.

* `azureDevOps` - Platform Generic Azure DevOps Pipeline YAML Files - _not for service modification_
* `infra` - Platform Services Infrastructure folder. Contains Service/Tenant infrastructure module instantiations.
* `services` - Contains the Services Folder Structure, i.e. _`<programme>/<service>/<infrastructure-param-config.bicepParams>`_. This is where all services infrastructure module instantiations will set, and is modified by Service/Tenant teams. 
```

├── .azureDevOps (not for service modification) 
│   ├── generic-template.yaml      
│   |── services-infra-template.yaml   
├── infra                                            
│   ├── bicep-generic (not for service modification)                                         
│   │   ├── cdn/.bicep
|   |   |   ├── sub-module-a
|   |   |   └── sub-module-b
|   |   └── application-domain.main.bicep
|   |   |
│   │   └── service-bus/.bicep
|   |   |   ├── sub-module-a
|   |   |   └── sub-module-b
|   |   └── service-bus-namespace.main.bicep     
|   |   |          
│   |── services (for Platform Tenants/Services)
│   |   ├── <programme> (i.e. ffc)
|   |   |── deploy-services-infra.yaml (Programme Pipeline)
|   |   |   ├── <programme>-<service-name> (ffc-demo)
|   |   |   |   └── application-domain.main.bicepparams
|   |   |   | 
│   |   ├── <programme> (i.e. bob)
|   |   |── deploy-services-infra.yaml (Programme Pipeline)
|   |   |   ├── <programme>-<service-name> (bob-service)
|   |   |   |   └── application-domain.main.bicepparams 
                                 
```

## Key principals to note:

- Each Azure component has a .bicepParams file containing the required infrastructure configuration. It is convention-based on the names of the Azure components.
- Each programme has its own shared, agnostic Pipeline - that re-uses ADP Pipeline Common. All services must extend this.
- The 'environments' can be configured at multiple levels, depending on your requirement: _Resource_, _Programme/Project_ or _Default RTL_.
- Automation sets up the initial structure and consumes the default RTL pattern. On-going changes are either fully automated or PR-reviewed on demand by GitHub 'Code Owners'.
- The Default RTL is: Dev, Test, Pre-Prod and Production.

### How to use Custom Environments
The following documentation describes the 'Resource', 'Programme/Project' and 'Default RTL' environment configurations that are possible on the Platform. The reasoning to provide multiple levels is to allow teams a high degree of flexibility and re-useable configuration depending on their deployment requirements. 

| By default, all teams will inherit the 'Default RTL' which includes: Development, Test, Pre-Production and Production (DEV1, TST1, PRE1, PRD1). Other environments also exist as required, such as Sandpit (SND1-3, Demo (DMO1), etc. |
|:----------|

Documentation can be found here: [ADP Environments](https://dev.azure.com/defragovuk/DEFRA-FFC/_wiki/wikis/DEFRA-FFC.wiki/16074/Environments)

#### Resource level:
Within the `services/<programme>/<project-service>` folder, add a `component-custom-evns.yaml` (i.e., _application-domain-custom-envs.yaml_) file with the structure defined in the example below. You may edit the `'environments'` block with your own from the defined list of SND1, DEV1, TST1, DMO1, PRE1, PRD1. You can specific the Azure Regions (primary/support UK South) and the Deployment Branches as needed. 

| Note: On your ADO Pipeline Run, you need to select: *Use Custom Environments*. |
|:----------|

```
parameters:
  - name: deployFromFeature
    type: boolean
    default: false
  - name: program
    type: string
  - name: service
    type: string
  - name: resource
    type: string

extends:
  template: /.azuredevops/templates/services-infra-template.yaml
  parameters:
    environments: 
      - name: 'snd1'
        serviceConnection: AZD-ADP-SND1
        deploymentBranches:
          - 'refs/heads/main'
        developmentEnvironment: true
        azureRegions:
          primary: 'UKSouth'
    deployFromFeature: ${{ parameters.deployFromFeature }}
    program: ${{ parameters.program }}
    service: ${{ parameters.service }}
    resource: ${{ parameters.resource }}

```

#### Programme/Project level:
Within `services/<programme>` folder, use your `deploy-services-infra.yaml` file that is already pre-configured and add custom, programme wide environments, for example:

```

extends:
  template: /.azuredevops/templates/generic-template.yaml
  parameters:
    deployFromFeature: ${{ parameters.deployFromFeature }}
    useCustomEnvironments: ${{ parameters.useCustomEnvironments }}
    program: ffc
    service: ${{ parameters.service }}
    resource: ${{ parameters.resource }}
    environments: 
      - name: 'dev1'
        serviceConnection: AZD-ADP-DEV1
        deploymentBranches:
          - 'refs/heads/main'
        developmentEnvironment: true
        azureRegions:
          primary: 'UKSouth'
```

#### Default RTL Environments:
To use the standard list (defined here: [ADP Environments](https://dev.azure.com/defragovuk/DEFRA-FFC/_wiki/wikis/DEFRA-FFC.wiki/16074/Environments)) Do not add Resource level environments/config, do not configure programme level environments/config, and do not select `Use Custom Environments` on the ADO Pipeline run.

Note: priority order is: 
- Resource > Programme (if Resource level supplied, and 'use custom environments' in ADO pipeline is checked)
- Programme > Default RTL (if Programme level supplied)
