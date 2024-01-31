@description('Required. The name of the afd endpoint.')
param afdEndpointName string = '#{{ afdClusterEndpointName }}'

@description('Required. The name of the service.')
param appEndpointName string

@description('Optional. The name of custom hostname for origin.')
param originCustomHost string = ''

@description('Optional. Use Private Link for origin. Default to true.')
param usePrivateLink bool = true

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. The state of the route.')
param enabledState string = 'Enabled'

@description('Required')
param forwardingProtocol string = 'HttpOnly'

@description('Optional. The rules to apply to the route.')
param ruleSets array = []

@description('Optional. The global rules to apply to the route. These are existing global rule set defined for ADP which are setup in frontdoor profile.')
param globalRuleSets array = [
  {
    name: 'ResponseHeaderRuleSet'
  }
]

var location = '#{{ location }}'
var dnsZoneName = '#{{ publicDnsZoneName }}'
var dnsZoneResourceGroup = '#{{ cdnResourceGroup }}'

var profileName = '#{{ cdnProfileName }}'
var loadBalancerPlsName = '#{{ aksLoadBalancerPlsName }}'
var loadBalancerPlsResourceGroup = '#{{ aksResourceGroup }}-Managed'
var subscriptionId = '#{{ subscriptionId }}'

var hostName = '${appEndpointName}.${dnsZoneName}'

var originCustomHostName = toLower(replace(originCustomHost, 'https://', ''))

var hostHeader = (originCustomHostName == '' && hostName !='') ? hostName : originCustomHostName

var customDomainConfig = {
  name: appEndpointName
  hostName: hostName
  certificateType: 'ManagedCertificate'
}

var originGroupConfig = {
  healthProbeSettings: {}
  loadBalancingSettings: {
    additionalLatencyInMilliseconds: 0
    sampleSize: 4
    successfulSamplesRequired: 2
  }
  sessionAffinityState: 'Disabled'
  origins: [
    {
      name: '${appEndpointName}-${location}-primary'
    }
  ]
}

module profile_custom_domain '.bicep/customdomain/main.bicep' = {
  name: '${uniqueString(deployment().name)}-CustomDomain'
  params: {
    name: customDomainConfig.name
    profileName: profileName
    afdEndpointName: afdEndpointName
    dnsZoneName: dnsZoneName
    dnsZoneResourceGroup: dnsZoneResourceGroup
    hostName: customDomainConfig.hostName
    certificateType: customDomainConfig.certificateType
  }
}

resource aks_loadbalancer_pls 'Microsoft.Network/privateLinkServices@2023-05-01' existing = if (usePrivateLink) {
  name: loadBalancerPlsName
  scope: resourceGroup(subscriptionId, loadBalancerPlsResourceGroup)
}

module profile_origionGroup '.bicep/origingroup/main.bicep' = {
  name: '${uniqueString(deployment().name)}-Profile-OrigionGroup'
  dependsOn: [
    profile_custom_domain
  ]
  params: {
    name: appEndpointName
    profileName: profileName
    healthProbeSettings: originGroupConfig.healthProbeSettings
    loadBalancingSettings: originGroupConfig.loadBalancingSettings
    sessionAffinityState: originGroupConfig.sessionAffinityState
    origins: map(originGroupConfig.origins, origin => {
        name: origin.name
        hostName: usePrivateLink ? aks_loadbalancer_pls.properties.alias : originCustomHostName
        sharedPrivateLinkResource: usePrivateLink ? {
          privateLink: {
            id: aks_loadbalancer_pls.id
          }
          privateLinkLocation: aks_loadbalancer_pls.location
          requestMessage: appEndpointName
        } : null
        originHostHeader:  hostHeader
      })
  }
}


module profile_ruleSet '.bicep/ruleset/main.bicep' = [for (ruleSet, index) in ruleSets: {
  name: '${uniqueString(deployment().name)}-Profile-RuleSet-${index}'
  params: {
    name: ruleSet.name
    profileName: profileName
    rules: ruleSet.rules
  }
}]

module afd_endpoint_route '.bicep/route/main.bicep' = {
  name: '${uniqueString(deployment().name)}-Profile-AfdEndpoint-Route'
  dependsOn: [
    profile_custom_domain
    profile_origionGroup
    profile_ruleSet
  ]
  params: {
    name: appEndpointName
    profileName: profileName
    afdEndpointName: afdEndpointName
    customDomainName: customDomainConfig.name
    enabledState: enabledState
    forwardingProtocol: forwardingProtocol
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Disabled'
    originGroupName: profile_origionGroup.outputs.name
    ruleSets: ruleSets
    globalRuleSets: globalRuleSets
  }
}
