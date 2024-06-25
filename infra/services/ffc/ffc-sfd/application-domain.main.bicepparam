using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = '#{{ appEndpoint }}'

param dnsZoneName = '#{{ dnsZoneName }}'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
