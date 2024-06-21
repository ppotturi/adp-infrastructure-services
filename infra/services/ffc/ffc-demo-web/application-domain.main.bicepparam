using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = 'ffc-demo-web'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
