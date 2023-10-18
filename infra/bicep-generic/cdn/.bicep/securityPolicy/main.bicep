@description('Required. The name of the security policy')
param name string

param profileName string

param wafPolicyName string

param customDomainName string

resource profile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: profileName

  resource custom_domain 'customDomains@2023-05-01' existing = {
    name: customDomainName
  }
}

resource waf_policy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' existing = {
  name: wafPolicyName
}

resource security_policy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  name: name
  parent: profile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: waf_policy.id
      }
      associations: [
        {
          domains: [
            {
              id: profile::custom_domain.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}
