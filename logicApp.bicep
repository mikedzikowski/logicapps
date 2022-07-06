param subscriptionId string = 'f4972a61-1083-4904-a4e2-a790107320bf'
param workflows_GetImageVersion_name string = 'GetImageVersion10'
param connections_azureautomation_externalid string = '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/resourceGroups/avdtest/providers/Microsoft.Web/connections/azureautomation'
param location string = 'usgovvirginia'
param recurrenceFrequency string = 'Minute'
param recurrenceInterval int = 5
param recurrenceType string = 'Recurrence'
param automationAccountName string = 'avdtest'
param automationAccountResourceGroup string = 'avdtest'
param automationAccountLocation string = 'usgovvirginia'
param runbookNewHostPoolRipAndReplace string = 'New-HostPoolRipAndReplace'
param runbookScheduleRunbookName string = 'Get-RunBookSchedule'
param runbookGetSessionHostVm string = 'Get-SessionHostVirtualMachine'
param runbookMarketPlaceImageVersion string = 'Get-MarketPlaceImageVersion'
param waitForRunBook bool = true
param falseExpression bool = false
param trueExpression bool = true
param resourceGroupName string = 'avdtest'
param deploymentNameSuffix string = utcNow()
param keyVaultName string = 'kv-baseline-til-001'
param keyVaultResourceGroup string = 'rg-baseline-til-001'

//
param workflows_GetBlobUpdate_name string = 'GetBlobUpdate10'
param automationAccountConnectionName string = 'azureautomation'
param blobConnectionName string = 'azureblob'
param identityType string = 'SystemAssigned'
param state string = 'Enabled'
param schema string = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
param contentVersion string = '1.0.0.0'
param connectionType string = 'Object'
param triggerFrequency string = 'Minute'
param triggerInterval int = 3
param container string =  'avdtest2'
param hostPoolName string = 'ProdMirror'
param checkBothCreatedAndModifiedDateTime bool = false
param maxFileCount int = 10

//
param storageAccountName string = 'avdtest2'

//
param tenantId string = 'f7fd127b-9a9f-4748-b8a4-21b7d7f10fbd'
param clientId string = 'd3e8677d-b330-4546-988c-d678dcdf79ff'
param displayName string = 'azureautomation'
param iconUri string = 'https://connectoricons-prod.azureedge.net/releases/v1.0.1538/1.0.1538.2619/azureautomation/icon.png'
param apiType string = 'Microsoft.Web/locations/managedApis'
param description string = 'Azure Automation provides tools to manage your cloud and on-premises infrastructure seamlessly.'
param brandColor string = '#56A0D7'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
    name: keyVaultName
    scope: resourceGroup(subscriptionId, keyVaultResourceGroup )
  }

module automationAccountConnection 'modules/automationAccountConnection.bicep'= {
  name: 'automationAccount'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    clientSecret: keyVault.getSecret('clientsecret')
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId:subscriptionId
    tenantId: tenantId
    clientId:clientId
    displayName: displayName
    iconUri:iconUri
    apiType:apiType
    description:description
    brandColor:brandColor
  }
}

module blobConnection 'modules/blobConnection.bicep'= {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    storageName: storageAccountName
    name: blobConnectionName
  }
}

module getImageVersionlogicApp 'modules/logicapp_getimageversion.bicep' = {
  name: 'getImageVersionlogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
  subscriptionId:subscriptionId
  workflows_GetImageVersion_name:workflows_GetImageVersion_name
  connections_azureautomation_externalid:connections_azureautomation_externalid
  location:location
  state:state
  recurrenceFrequency:recurrenceFrequency
  recurrenceType:recurrenceType
  recurrenceInterval:recurrenceInterval
  automationAccountName:automationAccountName
  automationAccountLocation:automationAccountLocation
  automationAccountResourceGroup:automationAccountResourceGroup
  runbookNewHostPoolRipAndReplace:runbookNewHostPoolRipAndReplace
  getRunbookScheduleRunbookName:runbookScheduleRunbookName
  getRunbookGetSessionHostVm:runbookGetSessionHostVm
  getGetMarketPlaceImageVersion:runbookMarketPlaceImageVersion
  waitForRunBook:waitForRunBook
  falseExpression:falseExpression
  trueExpression:trueExpression
  hostPoolName:hostPoolName
  }
  dependsOn: [
    automationAccountConnection
    blobConnection
  ]
}

module getBlobUpdateLogicApp 'modules/logicapp_getblobupdate.bicep' = {
  name: 'getBlobUpdateLogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params:{
    location:location
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    blobConnectionName: blobConnectionName
    identityType: identityType
    state: state
    schema: schema
    contentVersion: contentVersion
    connectionType: connectionType
    triggerFrequency: triggerFrequency
    triggerInterval: triggerInterval
    container: container
    hostPoolName: hostPoolName
    checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
    maxFileCount: maxFileCount
  }
  dependsOn: [
    automationAccountConnection
    blobConnection
  ]
}
