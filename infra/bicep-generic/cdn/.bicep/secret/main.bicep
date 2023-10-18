
@description('Required. The name of the secrect.')
param name string

@description('Conditional. The name of the parent CDN profile. Required if the template is used in a standalone deployment.')
param profileName string

@allowed([
  'AzureFirstPartyManagedCertificate'
  'CustomerCertificate'
  'ManagedCertificate'
  'UrlSigningKey'
])
@description('Required. The type of the secrect.')
param type string = 'AzureFirstPartyManagedCertificate'

@description('Conditional. The resource ID of the secrect source. Required if the type is CustomerCertificate.')
param secretSourceResourceId string = ''

@description('Optional. The version of the secret.')
param secretVersion string = ''

@description('Optional. The subject alternative names of the secrect.')
param subjectAlternativeNames array = []

@description('Optional. Indicates whether to use the latest version of the secrect.')
param useLatestVersion bool = false


resource profile 'Microsoft.Cdn/profiles@2023-05-01' existing = {
  name: profileName
}

resource profile_secrect 'Microsoft.Cdn/profiles/secrets@2023-05-01' = {
  name: name
  parent: profile
  properties: {
    parameters: (type == 'CustomerCertificate') ? {
      type: type
      secretSource: {
        id: secretSourceResourceId
      }
      secretVersion: secretVersion
      subjectAlternativeNames: subjectAlternativeNames
      useLatestVersion: useLatestVersion
    } : null
  }
}

@description('The name of the secrect.')
output name string = profile_secrect.name

@description('The resource ID of the secrect.')
output resourceId string = profile_secrect.id

@description('The name of the resource group the secret was created in.')
output resourceGroupName string = resourceGroup().name
