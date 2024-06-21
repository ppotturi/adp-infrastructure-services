using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = 'coreai-mcu-frontend'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
