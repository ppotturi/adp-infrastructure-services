using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = 'fcp-find-ai-frontend'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
