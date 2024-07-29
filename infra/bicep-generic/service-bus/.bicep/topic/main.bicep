param namespaceName string
param topicName string
param roledefinitionName string
param principalIds array

var allowedRoleNames = {
  'Azure Service Bus Data Receiver': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
  )
  'Azure Service Bus Data Sender': subscriptionResourceId(
    'Microsoft.Authorization/roleDefinitions',
    '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  )
}

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName

  resource topic 'topics@2022-10-01-preview' existing = {
    name: topicName
  }
}

resource topic_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in principalIds: {
  scope: namespace::topic
  name: guid(namespace::topic.id, principalId, roledefinitionName)
    properties: {
      roleDefinitionId: allowedRoleNames[?roledefinitionName] ?? null
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }]

type roleAssignmentType = {
  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string
  
}[]?
