@description('Required. The name for the DNS records.')
param dnsRecodName string

@description('Required. The name of the DNS zone.')
param dnsZoneName string

@description('Required. The name of the endpoint host.')
param endpointHostName string

@description('Required. The validation token for the DNS TXT records.')
param txtValidationToken string

var dnsRecordTimeToLive = 300

resource dnsZone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: dnsZoneName
}

resource cnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: dnsZone
  name: dnsRecodName
  properties: {
    TTL: dnsRecordTimeToLive
    CNAMERecord: {
      cname: endpointHostName
    }
  }
}

resource validationTxtRecord 'Microsoft.Network/dnsZones/TXT@2023-07-01-preview' = {
  parent: dnsZone
  name: '_dnsauth.${dnsRecodName}'
  properties: {
    TTL: dnsRecordTimeToLive
    TXTRecords: [
      {
        value: [
          txtValidationToken
        ]
      }
    ]
  }
}

