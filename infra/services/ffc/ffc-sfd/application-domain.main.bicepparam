using '../../../bicep-generic/cdn/application-domain.main.bicep'

param appEndpointName = 'ffc-sfd'

param enabledState = 'Enabled'

param wafName = '#{{ wafPolicyName }}'
