/*=====================================================================================================================================
=                                                                                                                                    =
=                                                                                                                                    =
= https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep?tabs=azure-spring-apps-enterprise  =                                                    *
=                                                                                                                                    =
=                                                                                                                                    =
=====================================================================================================================================*/


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring?tabs=bicep
@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliasa${uniqueString(resourceGroup().id, subscription().id)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

// https://docs.microsoft.com/en-us/rest/api/containerregistry/registries/check-name-availability
@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = appName

@description('The Azure Active Directory tenant ID that should be used to manage Azure Spring Apps Apps Identity.')
param tenantId string = subscription().tenantId

@description('The Log Analytics workspace name used by Azure Spring Apps instance')
param logAnalyticsWorkspaceName string = 'log-${appName}'

param appInsightsName string = 'appi-${appName}'
param appInsightsDiagnosticSettingsName string = 'dgs-${appName}-send-logs-and-metrics-to-log-analytics'

@description('The Azure Spring Apps instance name')
param azureSpringAppsInstanceName string = 'asae-${appName}'

// Check SKU REST API : https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0
@description('The Azure Spring Apps SKU Capacity, ie Max App instances')
@minValue(8)
@maxValue(25)
param azureSpringAppsSkuCapacity int = 25

@description('The Azure Spring Apps SKU name. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
@allowed([
  'BO'
  'S0'
  'E0'
])
param azureSpringAppsSkuName string = 'E0'

@allowed([
  'Basic'
  'Standard'
  'Enterprise'
])
@description('The Azure Spring Apps SKU Tier. Check it out at https://learn.microsoft.com/en-us/rest/api/azureSpringApps/skus/list#code-try-0')
param azureSpringAppsTier string = 'Enterprise'

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

param zoneRedundant bool = false

@description('The Azure Spring Apps monitoring Settings name. see https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-build-service?tabs=azure-portal')
@allowed([
  'default'
  'binding-ai'
])
param monitoringSettingsName string = 'binding-ai'

@description('The Azure Spring Apps Service Registry name. Only "default" is supported')
@allowed([
  'default'
])
param serviceRegistryName string = 'default'

@description('The Azure Spring Apps Application Configuration Service name. Only "default" is supported')
@allowed([
  'default'
])
param applicationConfigurationServiceName string = 'default'

@description('The Azure Spring Apps API Portal name. Only "default" is supported')
@allowed([
  'default'
])
param apiPortalName string = 'default'

@description('The Azure Spring Apps API Portal SSO Property clientId ')
@secure()
param apiPortalSsoClientId string

@description('The Azure Spring Apps API Portal SSO Property clientSecret ')
@secure()
param apiPortalSsoClientSecret string

@description('The Azure Spring Apps API Portal SSO Property issuerUri ')
@secure()
param apiPortalSsoIssuerUri string

@description('The Azure Spring Apps API Portal SSO Property ssoEnabled ')
param apiPortalSsoEnabled bool = false


@description('The Azure Spring Apps Spring Cloud Gateway name. Only "default" is supported')
@allowed([
  'default'
])
param gatewayName string = 'default'

@description('The Spring Cloud Gateway server URL which is unknow the first time you run Bicep')
param gatewayServerUrl string = 'asae-XXXX-gateway-424242.svc.azuremicroservices.io/'

@description('The Azure Spring Apps Application Configuration Service Git URI (The repo must be public).')
param gitConfigURI string

@allowed([
  'default'
])
@description('The Azure Spring Apps Application Configuration Service Git Repository name. Only "default" is supported')
param gitRepoName string  = 'default'

@description('The Azure Spring Apps Config Server Git label (branch/tag). Config Server takes master (on Git) as the default label if you do not specify one. To avoid Azure Spring Apps Config Server failure, be sure to pay attention to the default label when setting up Config Server with GitHub, especially for newly-created repositories. See https://learn.microsoft.com/en-us/azure/spring-apps/how-to-config-server https://docs.spring.io/spring-cloud-config/docs/3.1.4/reference/html/#_default_label . The default label used for Git is main. If you do not set spring.cloud.config.server.git.defaultLabel and a branch named main does not exist, the config server will by default also try to checkout a branch named master. If you would like to disable to the fallback branch behavior you can set spring.cloud.config.server.git.tryMasterBranch to false.')
param configServerLabel string = 'main'

@description('The Azure Spring Apps Build Agent pool name. Only "default" is supported') // to be checked
@allowed([
  'default'
])
param buildAgentPoolName string = 'default'

@description('The Azure Spring Apps Build service name. Only "{azureSpringAppsInstanceName}/default" is supported') // to be checked
@allowed([
  'default'
])
param buildServiceName string = 'default'

@description('The Azure Spring Apps Java Builder name.')
param builderName string = 'java-builder'

@description('The Azure Spring Apps Java Builder version. See https://network.tanzu.vmware.com/products/tanzu-base-bionic-stack#/releases/1218795/artifact_references')
@allowed([
  'base'
  'full'
])
param builderVersion string = 'full'

@description('The Azure Spring Apps Java Build name')
param buildName string = 'build-${appName}'

@description('The Azure Spring Apps Java Build Environment varibales: Space-separated environment variables in "key[=value]" format: <key1=value1>, <key2=value2>. Ex: BP_JVM_VERSION=Java_11 .')
param buildEnvJvmVersion string = 'Java_11'

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

var kvURL = 'https://${kvName}.vault.azure.net'

@description('The config-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param configServerAppIdentityName string = 'id-asa-${appName}-petclinic-config-server-dev-${location}-101'

@description('The api-gateway Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param apiGatewayAppIdentityName string = 'id-asa-${appName}-petclinic-api-gateway-dev-${location}-101'

@description('The UI for ASA-E Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param uiAppIdentityName string = 'id-asa-${appName}-petclinic-ui-dev-${location}-101'

@description('The customers-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param customersServiceAppIdentityName string = 'id-asa-${appName}-petclinic-customers-service-dev-${location}-101'

@description('The vets-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param vetsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-vets-service-dev-${location}-101'

@description('The visits-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param visitsServiceAppIdentityName string = 'id-asa-${appName}-petclinic-visits-service-dev-${location}-101'

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
  scope: kvRG
}
// pre-req: https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-azure-cli#prerequisites
resource azureSpringApps 'Microsoft.AppPlatform/Spring@2023-03-01-preview' = {
  name: azureSpringAppsInstanceName
  location: location
  sku: {
    capacity: azureSpringAppsSkuCapacity
    name: azureSpringAppsSkuName
    tier: azureSpringAppsTier
  }
  properties: {
    zoneRedundant: zoneRedundant
    //
    //marketplaceResource: {
    //  plan:
    //  product:
    //  publisher:
    //}
    //
  }
}

output azureSpringAppsResourceId string = azureSpringApps.id
output azureSpringAppsFQDN string = azureSpringApps.properties.fqdn
output azureSpringAppsOutboundPubIP array = azureSpringApps.properties.networkProfile.outboundIPs.publicIPs // /!\ has 2 IP separated from a coma, ex: 20.31.114.2,20.238.165.131

resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/diagnosticsettings?tabs=bicep
resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: appInsightsDiagnosticSettingsName
  scope: azureSpringApps
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationConsole'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'SystemLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'IngressLogs'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }    
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-infrastructure-vnet-bicep?tabs=azure-spring-apps-enterprise
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-application-insights?pivots=sc-enterprise-tier
resource azureSpringAppsMonitoringSettings 'Microsoft.AppPlatform/Spring/buildServices/builders/buildpackBindings@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  // name: '${azureSpringApps.name}/${buildServiceName}/${builderName}/${monitoringSettingsName}' default (for Build Service ) /default (Builder) /default (Build Pack binding name)
  name: '${azureSpringApps.name}/default/default/default' 
  properties: {
    bindingType: 'ApplicationInsights'
    launchProperties: {
      properties: {
        sampling_percentage: '10'
        connection_string: appInsights.properties.ConnectionString // /!\ ConnectionString for Enterprise tier ,  InstrumentationKey for Standard Tier 
      }
    }   
  }
  dependsOn: [
    buildService
  ]
}

resource azureSpringAppsJavaBuilderAppInsightsMonitoringSettings 'Microsoft.AppPlatform/Spring/buildServices/builders/buildpackBindings@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  // name: '${azureSpringApps.name}/${buildServiceName}/${builderName}/${monitoringSettingsName}' default (for Build Service ) /default (Builder) /default (Build Pack binding name)
  name: '${azureSpringApps.name}/${buildServiceName}/${builderName}/${monitoringSettingsName}' 
  properties: {
    bindingType: 'ApplicationInsights'
    launchProperties: {
      properties: {
        sampling_percentage: '10'
        connection_string: appInsights.properties.ConnectionString // /!\ ConnectionString for Enterprise tier ,  InstrumentationKey for Standard Tier 
      }
    }   
  }
  dependsOn: [
    buildService
    builder
  ]
}

resource apiGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: apiGatewayAppIdentityName
}

resource uiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: uiAppIdentityName
}

resource customersServicedentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: customersServiceAppIdentityName
}

resource vetsServiceAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: vetsServiceAppIdentityName
}

resource visitsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: visitsServiceAppIdentityName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/configurationservices?pivots=deployment-language-bicep
resource appconfigservice 'Microsoft.AppPlatform/Spring/configurationServices@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: applicationConfigurationServiceName
  parent: azureSpringApps
  properties: {
    settings: {
      gitProperty: {
        repositories: [
          {
            name: gitRepoName
            label: configServerLabel
            // https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-application-configuration-service#pattern
            // {profile} - Optional. The name of a profile whose properties you may be retrieving. 
            // An empty value, or the value default, includes properties that are shared across profiles. 
            // Non-default values include properties for the specified profile and properties for the default profile.
            patterns: [
              'application'
              'application/mysql' // https://github.com/MicrosoftDocs/azure-docs/issues/102826#issuecomment-1361369675
            ]
            //searchPaths: [
            //  '/'
            //]
            uri: gitConfigURI
          }
        ]
      }
    }
  }
}

resource customersserviceapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'customers-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${customersServicedentity.id}': {}
    }      
  }
  properties: {
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }
      buildService: {
        resourceId: '${azureSpringApps.id}/buildServices/${buildServiceName}'
      }
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    serviceRegistry
    buildService
  ]  
}
output customersServiceIdentity string = customersserviceapp.identity.userAssignedIdentities['${customersServicedentity.id}'].principalId

resource vetsserviceapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'vets-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vetsServiceAppIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }
      buildService: {
        resourceId: '${azureSpringApps.id}/buildServices/${buildServiceName}'
      }   
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    serviceRegistry
    buildService    
  ]  
}
output vetsServiceIdentity string = vetsserviceapp.identity.userAssignedIdentities['${vetsServiceAppIdentity.id}'].principalId

resource visitsservicerapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'visits-service'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${visitsServiceIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }
      buildService: {
        resourceId: '${azureSpringApps.id}/buildServices/${buildServiceName}'
      }
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    serviceRegistry
    buildService    
  ]
}
output visitsServiceIdentity string = visitsservicerapp.identity.userAssignedIdentities['${visitsServiceIdentity.id}'].principalId


// https://github.com/MicrosoftDocs/azure-docs/issues/102825
resource apigatewayapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'api-gateway'
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apiGatewayIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }
      buildService: {
        resourceId: '${azureSpringApps.id}/buildServices/${buildServiceName}'
      }    
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    serviceRegistry
    buildService    
    customersserviceapp
    vetsserviceapp
    visitsservicerapp
  ]  
}
output apiGatewayIdentity string = apigatewayapp.identity.userAssignedIdentities['${apiGatewayIdentity.id}'].principalId

resource uiapp 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'ui-asa-e' // App name must be between 4 and 32 characters long
  location: location
  parent: azureSpringApps
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uiIdentity.id}': {}
    }  
  }
  properties: {
    addonConfigs: {
      azureMonitor: {
        enabled: true
      }
      applicationConfigurationService: {
        resourceId: '${azureSpringApps.id}/configurationServices/${applicationConfigurationServiceName}'
      }
      serviceRegistry: {
          resourceId: '${azureSpringApps.id}/serviceRegistries/${serviceRegistryName}'
      }
      buildService: {
        resourceId: '${azureSpringApps.id}/buildServices/${buildServiceName}'
      }    
    }
    httpsOnly: false
    public: true
    temporaryDisk: {
      mountPath: '/tmp'
      sizeInGB: 5
    }
  }
  dependsOn: [
    appconfigservice
    serviceRegistry
    buildService    
    customersserviceapp
    vetsserviceapp
    visitsservicerapp
  ]  
}

output uiIdentity string = uiapp.identity.userAssignedIdentities['${uiIdentity.id}'].principalId

/*
az spring app binding --help
Group
    az spring app binding : Commands to manage bindings with Azure Data Services, you need to
    manually restart app to make settings take effect.

resource customersbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'customers-service-binding'
  parent: customersserviceapp
  properties: {
    bindingParameters: {}
    resourceId: customersserviceapp.id
    key: 'customers-service' // There is no API Key for MySQL
  }
  dependsOn: [
    serviceRegistry
  ]
}

resource vetsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'vets-service-binding'
  parent: vetsserviceapp
  properties: {
    bindingParameters: {}
    resourceId: vetsserviceapp.id
    key: 'vets-service' // There is no API Key for MySQL
  }
  dependsOn: [
    serviceRegistry
  ]  
}

resource visitsbinding 'Microsoft.AppPlatform/Spring/apps/bindings@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'visits-service-binding'
  parent: visitsservicerapp
  properties: {
    bindingParameters: {
      //databaseName: 'mydb'
      //xxx: '' // username ? PWD ?
    }
    key: 'visits-service' // There is no API Key for MySQL
    resourceId: visitsservicerapp.id
  }
  dependsOn: [
    serviceRegistry
  ]  
}
*/

// Binding name can contain only lowercase letters, numbers and hyphens.
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-service-registry
/*
az spring service-registry bind \
--resource-group $RESOURCE_GROUP \
--service $AZURE_SPRING_APPS_NAME \
--app serviceA
*/

// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-deploy-apps-enterprise#activate-service-registration-and-discovery
// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/serviceregistries?pivots=deployment-language-bicep
resource serviceRegistry 'Microsoft.AppPlatform/Spring/serviceRegistries@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: serviceRegistryName
  parent: azureSpringApps

}
output serviceRegistryId string = serviceRegistry.id
//output serviceRegistryCpu string = serviceRegistry.properties.resourceRequests.cpu
//output serviceRegistryInstanceCount int = serviceRegistry.properties.resourceRequests.instanceCount
//output serviceRegistryMemory string = serviceRegistry.properties.resourceRequests.memory

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-09-01-preview/spring/apiportals?pivots=deployment-language-bicep
// https://learn.microsoft.com/en-us/azure/spring-apps/quickstart-configure-single-sign-on-enterprise
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-use-enterprise-api-portal
// az spring api-portal  update  --help
resource apiPortal 'Microsoft.AppPlatform/Spring/apiPortals@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: apiPortalName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1) // Number of instance
    tier: azureSpringAppsTier
  }
  properties: {
    gatewayIds: [
        //'${azureSpringApps.id}/gateways/${gatewayName}'
        gateway.id
      ]
    httpsOnly: false
    public: true
  }
  dependsOn:  [
    gateway
  ]
}
output apiPortalId string = apiPortal.id
output apiPortalUrl string = apiPortal.properties.url
output gatewayIds array = apiPortal.properties.gatewayIds

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2022-11-01-preview/spring/gateways?pivots=deployment-language-bicep
resource gateway 'Microsoft.AppPlatform/Spring/gateways@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: gatewayName
  parent: azureSpringApps
  sku: {
    name: azureSpringAppsSkuName
    capacity: any(1)
    tier: azureSpringAppsTier
  }
  properties: {
    httpsOnly: false // for custom domain ONLY ?
    public: true
    // az spring gateway update --help
    resourceRequests: {
      cpu: '1' // CPU resource quantity. Should be 500m or number of CPU cores.
      memory: '1Gi' // Memory resource quantity. Should be 512Mi or #Gi, e.g., 1Gi, 3Gi.
    }
    apiMetadataProperties: {
      title: 'Spring Cloud Gateway for Petclinic' // Title describing the context of the APIs available on the Gateway instance (default: Spring Cloud Gateway for K8S)
      description: '' // description of the APIs available on the Gateway instance (default: Generated OpenAPI 3 document that describes the API routes configured for '[Gateway instance name]' Spring Cloud Gateway instance deployed under '[namespace]' namespace.)
      version: '1.0.0' // Version of APIs available on this Gateway instance (default: unspecified)
      // serverUrl: gatewayServerUrl // Base URL that API consumers will use to access APIs on the Gateway instance.
      documentation: '' // Location of additional documentation for the APIs available on the Gateway instance
    }
    /* Spring Cloud Gateway APM feature is not enabled
    apmTypes: [
      'ApplicationInsights'
    ]
    */
    corsProperties: {
      allowCredentials: false
      allowedOrigins: [
        '*'
      ]
      allowedMethods: [
        'GET'
      ]
      allowedHeaders: [
        '*'
      ]
    }
  }
}

output gatewayId string = gateway.id
output gatewayUrl string = gateway.properties.url
// output gatewayApiserverUrl string = gateway.properties.apiMetadataProperties.serverUrl

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

// https://github.com/Azure/azure-rest-api-specs/blob/main/specification/appplatform/resource-manager/Microsoft.AppPlatform/preview/2023-03-01-preview/examples/ContainerRegistries_CreateOrUpdate.json
/*
resource containerregistry 'Microsoft.AppPlatform/Spring/containerRegistries@2023-03-01-preview' = {
  name: 'default' // only 'default' is supported.
  parent: azureSpringApps
  properties: {
    credentials : {
      type: 'BasicAuth'
      server: acr.properties.loginServer
      username: acr.listCredentials().username
      password: acr.listCredentials().passwords[0].value
    }
  }
}
*/

// https://github.com/Azure/azure-rest-api-specs/issues/18286
// Feature BuildService is not supported in Sku S0: https://github.com/MicrosoftDocs/azure-docs/issues/89924
// From 2023-03-01-preview API version, the default build service won't be created during provisioning a service instance by default
// 'existing' should be removed once the default build service is created.
resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  //scope: resourceGroup('my RG')
  name: '${azureSpringAppsInstanceName}/${buildServiceName}' 
  // parent: azureSpringApps
  properties: {
    // containerRegistry: acr.id can only use '--container-image' to deploy.
    /* read-only. Expressions cannot be assigned to read-only properties. 
    https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/2023-03-01-preview/spring/buildservices?pivots=deployment-language-bicep#buildservicepropertiesresourcerequests
    */
    resourceRequests: {
      //cpu: '1' // CPU resource quantity. Should be 500m or number of CPU cores.
      //memory: '2Gi' // Memory resource quantity. Should be 512Mi or #Gi, e.g., 1Gi, 3Gi.
    }
  }
  dependsOn: [
    azureSpringApps
  ]    
}

output buildServicekPackVersion string = buildService.properties.kPackVersion
//output buildServiceresourceRequestsCpu string = buildService.properties.resourceRequests.cpu
//output buildServiceresourceRequestsMemory string = buildService.properties.resourceRequests.memory

// /!\ should add ' existing' = if (azureSpringAppsTier=='Enterprise') {
resource buildagentpool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  // '{your-service-name}/default/default'  //{your-service-name}/{build-service-name}/{agenpool-name}
  name: '${azureSpringAppsInstanceName}/${buildServiceName}/${buildAgentPoolName}' // default/default as buildServiceName / agentpoolName
  properties: {
    poolSize: {
      name: 'S2'
    }
  }
  dependsOn: [
    azureSpringApps
    buildService
  ]  
}

// /!\ If you're using the tanzu-buildpacks/java-azure buildpack, we recommend that you set the BP_JVM_VERSION environment variable in the build-env argument.
// az spring build-service builder create --help
// https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-build-service?tabs=azure-portal#default-builder-and-tanzu-buildpacks
resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: builderName
  parent: buildService
  properties: {
    buildpackGroups: [
      {
        buildpacks: [
          {
            id: 'tanzu-buildpacks/java-azure'
          }
        ]
        name: 'java'
      }
    ]
    // https://docs.vmware.com/en/VMware-Tanzu-Buildpacks/services/tanzu-buildpacks/GUID-full-stack-release-notes.html
    // 
    stack: {
      id: 'io.buildpacks.stacks.jammy' // io.buildpacks.stacks.bionic-base or tanzu-base-bionic-stack ?   https://docs.pivotal.io/tanzu-buildpacks/stacks.html , OSS from https://github.com/paketo-buildpacks/java
      version: builderVersion // base or full  | NOT 1.2.35 https://network.tanzu.vmware.com/products/tanzu-base-bionic-stack#/releases/1218795/artifact_references
    }
  }
  dependsOn: [
    azureSpringApps
  ]
}

// https://github.com/Azure/Azure-Spring-Apps/issues/28
/* 
resource build 'Microsoft.AppPlatform/Spring/buildServices/builds@2022-12-01' = if (azureSpringAppsTier=='Enterprise') {
  name: buildName
  parent: buildService
  properties: {
    agentPool: buildagentpool.id
    builder: builder.id
    env: { // Space-separated environment variables in 'key[=value]' format: <key1=value1>, <key2=value2>. Ex: BP_JVM_VERSION=Java_11
      BP_JVM_VERSION: buildEnvJvmVersion
    } 
    relativePath: '/'
  }
  dependsOn: [
    azureSpringApps
  ]
}
*/

/*
resource buildResult 'Microsoft.AppPlatform/Spring/buildServices/builds/results@2022-11-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'default'
  parent: build
  dependsOn: [
    azureSpringApps
  ]
}
*/


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring/devtoolportals?pivots=deployment-language-bicep
resource devToolPortals 'Microsoft.AppPlatform/Spring/DevToolPortals@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'default'
  parent: azureSpringApps
  properties: {
    public: true
    features: {
      applicationAccelerator: {
        state: 'Enabled'
      }
      applicationLiveView: {
        state: 'Enabled'
      }
    }
    /*
    ssoProperties: {
      clientId: apiPortalSsoClientId
      clientSecret: apiPortalSsoClientSecret
      metadataUrl: 'string'
      scopes: [
        'openid'
        'profile'
        'email'
      ]
    }
    */
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring/applicationaccelerators?pivots=deployment-language-bicep
resource appAccelerators 'Microsoft.AppPlatform/Spring/applicationAccelerators@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
 name: 'default'
 parent: azureSpringApps
 sku: {
   name: 'S1'
 }
}
output appAcceleratorsId string = appAccelerators.id
output appAcceleratorsComponents array = appAccelerators.properties.components

// az spring application-accelerator predefined-accelerator show -n "Acme Fitness Store" -g rg-iac-asa-petclinic-mic-srv
// Acme Fitness Store (does not work) or asa-acme-fitness-store ?
// Tanzu Java Restful Web App ? or asa-java-rest-service ?
// Node Express ? or asa-node-express ?
// Spring Cloud Serverless ? or asa-spring-cloud-serverless ? 
// C# Weather Forecast ? or asa-weatherforecast-csharp ?

// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring/applicationaccelerators/predefinedaccelerators?pivots=deployment-language-bicep
resource predefinedAcceleratorACME 'Microsoft.AppPlatform/Spring/applicationAccelerators/predefinedAccelerators@2023-03-01-preview' existing  = if (azureSpringAppsTier=='Enterprise') {
  name: 'asa-acme-fitness-store'
  parent: appAccelerators
}
output predefinedAcceleratorsId string = predefinedAcceleratorACME.id
output predefinedAcceleratorsName string = predefinedAcceleratorACME.name
output predefinedAcceleratorsDisplayName string = predefinedAcceleratorACME.properties.displayName


// https://learn.microsoft.com/en-us/azure/templates/microsoft.appplatform/spring/applicationliveviews?pivots=deployment-language-bicep
resource appLiveViews 'Microsoft.AppPlatform/Spring/applicationLiveViews@2023-03-01-preview' = if (azureSpringAppsTier=='Enterprise') {
  name: 'default'
  parent: azureSpringApps
 }
 output appLiveViewsId string = appLiveViews.id
 output appLiveViewsComponents array = appLiveViews.properties.components
