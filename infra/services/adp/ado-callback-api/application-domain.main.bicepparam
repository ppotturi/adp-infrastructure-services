using '../../../bicep-generic/cdn/application-domain.main.bicep'

param afdEndpointName = '#{{ environment_lower}}#{{ environmentId }}-adp-containerapps'

param appEndpointName = 'ado-callback-api'

param originCustomHost = '#{{ adoCallBackApiInternalHostName }}'

param usePrivateLink = false

param enabledState = 'Enabled'

param forwardingProtocol = 'HttpOnly'

param wafName = '#{{ wafPolicyName }}'
