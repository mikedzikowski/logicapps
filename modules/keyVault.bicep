// Creates a KeyVault with Private Link Endpoint
@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault Instance')
param tags object = {}

@description('The name of the Key Vault')
param keyvaultName string

@description('The id of the automation account')
param aaIdentityId string

@description('This is the built-in Key Vault Administrator role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-administrator')
resource keyVaultReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope:  subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}
resource keyVaultAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(aaIdentityId, keyVaultReaderRoleDefinition.id, keyvaultName)
  properties: {
    roleDefinitionId: keyVaultReaderRoleDefinition.id
    principalId: aaIdentityId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultName string = keyVault.name
