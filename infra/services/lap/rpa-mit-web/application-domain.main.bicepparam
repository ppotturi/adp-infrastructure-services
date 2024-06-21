using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = 'rpa-mit-web'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
