targetScope = 'subscription'

// Environment Parameters
param deploymentNameSuffix string = utcNow()
param resourceGroupName string = 'avdtest'
param location string = 'usgovvirginia'

// Automation Account Parameters
param automationAccountConnectionName string = 'azureautomation'
param automationAccountName string = 'avdtest'
param automationAccountResourceGroup string = 'avdtest'
param automationAccountLocation string = 'usgovvirginia'
param runbookNewHostPoolRipAndReplace string = 'New-HostPoolRipAndReplace'
param runbookScheduleRunbookName string = 'Get-RunBookSchedule'
param runbookGetSessionHostVm string = 'Get-SessionHostVirtualMachine'
param runbookMarketPlaceImageVersion string = 'Get-MarketPlaceImageVersion'

// GetImageVersion Logic App Parameters
param workflows_GetImageVersion_name string = 'GetImageVersion-demo2'
param recurrenceFrequency string = 'Minute'
param recurrenceInterval int = 5
param recurrenceType string = 'Recurrence'
param waitForRunBook bool = true
param falseExpression bool = false
param trueExpression bool = true

// Get BlobUpdate Logic App Parameters
param workflows_GetBlobUpdate_name string = 'GetBlobUpdate-demo2'
param blobConnectionName string = 'azureblob'
param identityType string = 'SystemAssigned'
param state string = 'Enabled'
param schema string = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
param contentVersion string = '1.0.0.0'
param connectionType string = 'Object'
param triggerFrequency string = 'Minute'
param triggerInterval int = 3
param container string = 'avdtest2'
param hostPoolName string = 'ProdMirror'
param checkBothCreatedAndModifiedDateTime bool = false
param maxFileCount int = 10

// Storage account name
param storageAccountName string = 'avdtest2'
param storageaAccountResourceGroupName string = '' 

// Role Id - make variable
param roleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

// AVD resource group
param hostPoolResourceGroupName string = 'rg-sharedservices-til-001'

// Variables
var subscriptionId = subscription().subscriptionId
var runbooks = [
  {
    name: 'Get-RunBookSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-RunBookSchedule.ps1'
  }
  {
    name: 'Get-MarketPlaceImageVersion'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-MarketPlaceImageVersion.ps1'
  }
  {
    name: 'Get-SessionHostVirtualMachine'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-SessionHostVirtualMachine.ps1'
  }
  {
    name: 'New-HostPoolRipAndReplace'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/New-HostPoolRipAndReplace.ps1'
  }
]

module storageAccount 'modules/storageAccount.bicep' = {
 name: storageAccountName
 scope: resourceGroup(subscriptionId, storageaAccountResourceGroupName)
 params:{
  storageAccountName:storageAccountName
  location:location
  storageAccountType: 'Standard_LRS'
  containerName: container
 }
}

module automationAccount 'modules/automationAccount.bicep' = {
  name: automationAccountName
  scope: resourceGroup(subscriptionId, automationAccountResourceGroup)
  params: {
    automationAccountName: automationAccountName
    location: location
    runbookNames: runbooks
  }
}

module automationAccountConnection 'modules/automationAccountConnection.bicep' = {
  name: 'automationAccountConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId: subscriptionId
    displayName: automationAccountConnectionName
  }
}

module blobConnection 'modules/blobConnection.bicep' = {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    storageName: storageAccountName
    name: blobConnectionName
  }
}

module rbacPermissionAzureAutomationConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-AAConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: getImageVersionlogicApp.outputs.imagePrincipalId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    getBlobUpdateLogicApp
    getImageVersionlogicApp
    storageAccount
  ]
}

module rbacBlobPermissionConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-blobConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: getBlobUpdateLogicApp.outputs.blobPrincipalId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    getBlobUpdateLogicApp
    getImageVersionlogicApp
    storageAccount
  ]
}

module rbacPermissionAzureAutomationAccount 'modules/rbacPermissions.bicep' = {
  name: 'rbac-automationAccount-deployment-${deploymentNameSuffix}'
  scope:resourceGroup(subscriptionId, hostPoolResourceGroupName)
  params: {
    principalId: automationAccount.outputs.aaIdentityId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    getBlobUpdateLogicApp
    getImageVersionlogicApp
    storageAccount
  ]
}

module getImageVersionlogicApp 'modules/logicappGetImageVersion.bicep' = {
  name: 'getImageVersionlogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    subscriptionId: subscriptionId
    workflows_GetImageVersion_name: workflows_GetImageVersion_name
    automationAccountConnectionName: automationAccountConnectionName
    location: location
    state: state
    recurrenceFrequency: recurrenceFrequency
    recurrenceType: recurrenceType
    recurrenceInterval: recurrenceInterval
    automationAccountName: automationAccountName
    automationAccountLocation: automationAccountLocation
    automationAccountResourceGroup: automationAccountResourceGroup
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    getRunbookScheduleRunbookName: runbookScheduleRunbookName
    getRunbookGetSessionHostVm: runbookGetSessionHostVm
    getGetMarketPlaceImageVersion: runbookMarketPlaceImageVersion
    waitForRunBook: waitForRunBook
    falseExpression: falseExpression
    trueExpression: trueExpression
    hostPoolName: hostPoolName
    identityType: identityType
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    storageAccount
  ]
}

module getBlobUpdateLogicApp 'modules/logicAppGetBlobUpdate.bicep' = {
  name: 'getBlobUpdateLogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    automationAccountName: automationAccountName
    automationAccountResourceGroup: automationAccountResourceGroup
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
    subscriptionId: subscriptionId
    runbookGetRunBookSchedule: runbookScheduleRunbookName
    runbookGetSessionHostVirtualMachine: runbookGetSessionHostVm
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    storageAccount
  ]
}
