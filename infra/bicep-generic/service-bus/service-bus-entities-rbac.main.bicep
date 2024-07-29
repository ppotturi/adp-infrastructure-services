@description('Required. The object Id of the service principal.')
param principalIds string

@description('Optional. The role assignments for topics.')
param topicsRoleAssignments roleAssignment

var namespaceName = '#{{infraResourceNamePrefix}}#{{nc_resource_servicebus}}#{{nc_instance_regionid}}01'

module topic_roleAssignments '.bicep/topic/main.bicep' = [
  for (roleAssignment, index) in (topicsRoleAssignments ?? []): {
    name: '${uniqueString(deployment().name)}-Topic-Rbac-${index}'
    params: {
      namespaceName: namespaceName
      topicName: roleAssignment.entityName
      roledefinitionName: roleAssignment.roleDefinitionName
      principalIds: json(principalIds)
    }
  }
]

type roleAssignment = {
  @description('Required. The name of the topic or queue.')
  entityName: string

  @description('Required. The role definition name to assign to the service principal.')
  roleDefinitionName: string
}[]?


