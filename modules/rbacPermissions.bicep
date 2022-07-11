param canDelegate bool = false
param description string = 'Contributor RBAC permission'
param principalId string
param roleId string

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, principalId)
  properties: {
    canDelegate: canDelegate
    description: description
    principalId: principalId
    roleDefinitionId:  resourceId('Microsoft.Authorization/roleDefinitions', roleId)
  }
}

output rbac string = rbac.properties.roleDefinitionId
