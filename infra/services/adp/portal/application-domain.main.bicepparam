using '../../../bicep-generic/cdn/application-domain.main.bicep'

param afdEndpointName = '#{{ environment_lower}}#{{ environmentId }}-adp-containerapps'

param appEndpointName = 'portal'

param originCustomHost = '#{{ AppGatewayPublicIP }}'

param usePrivateLink = false

param enabledState = 'Enabled'

param forwardingProtocol = 'HTTP'
