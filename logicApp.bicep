// Environment Parameters
param deploymentNameSuffix string = utcNow()
param resourceGroupName string = 'avdtest'
param keyVaultName string = 'kv-baseline-til-001'
param keyVaultResourceGroup string = 'rg-baseline-til-001'
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
param workflows_GetImageVersion_name string = 'GetImageVersion'
param recurrenceFrequency string = 'Minute'
param recurrenceInterval int = 5
param recurrenceType string = 'Recurrence'
param waitForRunBook bool = true
param falseExpression bool = false
param trueExpression bool = true

// Get BlobUpdate Logic App Parameters
param workflows_GetBlobUpdate_name string = 'GetBlobUpdate'
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

// Variables
var clientId = 'd3e8677d-b330-4546-988c-d678dcdf79ff'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

// Storage account name
param storageAccountName string = 'avdtest2'

// Service principal information
param iconUri string = 'https://connectoricons-prod.azureedge.net/releases/v1.0.1538/1.0.1538.2619/azureautomation/icon.png'
param apiType string = 'Microsoft.Web/locations/managedApis'
param description string = 'Azure Automation provides tools to manage your cloud and on-premises infrastructure seamlessly.'
param brandColor string = '#56A0D7'

var runbooks  = [
  {
    name: 'Get-RunBookSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-RunBookSchedule.ps1'
  }
  {
    name: 'Get-MarketPlaceImageVersion'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-MarketPlaceImageVersion.ps1'
  }
  {
    name:'Get-SessionHostVirtualMachine'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-SessionHostVirtualMachine.ps1'
  }
  {
    name: 'New-HostPoolRipAndReplace'
    uri: 'https://github.com/mikedzikowski/logicapps/blob/main/runbooks/New-HostPoolRipAndReplace.ps1'
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(subscriptionId, keyVaultResourceGroup)
}

module automationAcccount 'modules/automationAccount.bicep' = [for (runbook, i) in runbooks :  {
  name: '${automationAccountName}${runbook.name}${i}'
  scope: resourceGroup(subscriptionId, automationAccountResourceGroup)
  params: {
    automationAccountName: automationAccountName
    location: location
    uri: runbook.uri
    runbookName: runbook.name
  }
}]

module automationAccountConnection 'modules/automationAccountConnection.bicep' = {
  name: 'automationAccountConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    clientSecret: keyVault.getSecret('clientsecret')
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId: subscriptionId
    tenantId: tenantId
    clientId: clientId
    displayName: automationAccountConnectionName
    iconUri: iconUri
    apiType: apiType
    description: description
    brandColor: brandColor
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

module getImageVersionlogicApp 'modules/logicapp_getimageversion.bicep' = {
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
  }
  dependsOn: [
    automationAcccount
    automationAccountConnection
    blobConnection
  ]
}

module getBlobUpdateLogicApp 'modules/logicapp_getblobupdate.bicep' = {
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
    automationAcccount
    automationAccountConnection
    blobConnection
  ]
}
