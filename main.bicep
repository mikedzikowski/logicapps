targetScope = 'subscription'

param location string = deployment().location

// Environment
@allowed([
  'p'
  'd'
  's'
])
param Environment string = 's'

// GetImageVersion Logic App Parameters
param workflows_GetImageVersion_name string = 'GetImageVersionLogicApp'

@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
param recurrenceFrequency string = 'Day'
param recurrenceInterval int = 1

// Email Contact for Approval Flow
param emailContact string = 'micdz@microsoft.com'

// Get BlobUpdate Logic App Parameters
param workflows_GetBlobUpdate_name string = 'GetBlobUpdateLogicApp'
param container string = 'container'
param hostPoolName string = 'ProdMirror'

@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
param triggerFrequency string = 'Day'
param triggerInterval int = 1

// Exisiting AVD resource group
param hostPoolResourceGroupName string = 'rg-sharedservices-til-001'

param sessionHostResourceGroupName string = 'rg-sharedservices-til-001'

// UTC
param deploymentNameSuffix string  = utcNow()

param startTime string = '23:00'

// Variables
var subscriptionId = subscription().subscriptionId
var recurrenceType = 'Recurrence'
var waitForRunBook = true
var officeConnectionName =  'office365'
var automationAccountConnectionName = 'azureautomation'
var blobConnectionName = 'azureblob'
var identityType = 'SystemAssigned'
var state = 'Enabled'
var schema  = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
var contentVersion = '1.0.0.0'
var connectionType = 'Object'
var checkBothCreatedAndModifiedDateTime = false
var maxFileCount = 10
var roleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var runbookNewHostPoolRipAndReplace  = 'New-HostPoolRipAndReplace'
var runbookScheduleRunbookName = 'Get-RunBookSchedule'
var runbookGetSessionHostVm = 'Get-SessionHostVirtualMachine'
var runbookMarketPlaceImageVersion  = 'Get-MarketPlaceImageVersion'
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
  {
    name: 'New-AutomationSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/New-AutomationSchedule.ps1'
  }
]

var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne'
  norwayeast: 'ne2'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southeastasia: 'sa'
  southindia: 'si'
  swedencentral: 'sc'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'ia'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var LocationShortName = LocationShortNames[location]
var NamingStandard = '${Environment}-${LocationShortName}'

// Resource Group Naming
var ResourceGroups = [
  'rg-${NamingStandard}-aa'
  'rg-${NamingStandard}-la'
  'rg-${NamingStandard}-storage'
]

// Storage account name
var storageAccountName = replace('sa${NamingStandard}','-','')

// Automation Account Parameters
var automationAccountName = 'aa-${NamingStandard}'

var cloud = environment().name

// Resource Groups needed for the solution
resource resourceGroups 'Microsoft.Resources/resourceGroups@2020-10-01' = [for i in range(0, length(ResourceGroups)): {
  name: ResourceGroups[i]
  location: location
}]

module storageAccount 'modules/storageAccount.bicep' = {
 name: storageAccountName
 scope: resourceGroup(subscriptionId, ResourceGroups[2])
 params:{
  storageAccountName:storageAccountName
  location:location
  storageAccountType: 'Standard_LRS'
  containerName: container
 }
 dependsOn: [
  resourceGroups
]
}

module automationAccount 'modules/automationAccount.bicep' = {
  name: automationAccountName
  scope: resourceGroup(subscriptionId, ResourceGroups[0])
  params: {
    automationAccountName: automationAccountName
    location: location
    runbookNames: runbooks
  }
  dependsOn: [
    resourceGroups
  ]
}

module automationAccountConnection 'modules/automationAccountConnection.bicep' = {
  name: 'automationAccountConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[1])
  params: {
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId: subscriptionId
    displayName: automationAccountConnectionName
  }
  dependsOn: [
    automationAccount
    storageAccount
    resourceGroups
  ]
}

module blobConnection 'modules/blobConnection.bicep' = {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[1])
  params: {
    location: location
    storageName: storageAccountName
    name: blobConnectionName
    saResourceGroup:ResourceGroups[2]
    subscriptionId: subscriptionId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    storageAccount
    resourceGroups
  ]
}

module o365Connection 'modules/officeConnection.bicep' = {
  name: 'o365Connection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[1])
  params: {
    displayName: officeConnectionName
    location: location
    subscriptionId: subscriptionId
    connection_azureautomation_name: officeConnectionName
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    storageAccount
    resourceGroups
  ]
}

module rbacPermissionAzureAutomationConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-aaConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[0])
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
    resourceGroups
  ]
}

module rbacBlobPermissionConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-blobConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[0])
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
    resourceGroups
  ]
}

module rbacHostPoolPermissionAzureAutomationAccount 'modules/rbacPermissions.bicep' = {
  name: 'rbacHost-automationAccount-deployment-${deploymentNameSuffix}'
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
    resourceGroups
  ]
}

module rbacSessionHostPermissionAzureAutomationAccount 'modules/rbacPermissions.bicep' = {
  name: 'rbacSession-automationAccount-deployment-${deploymentNameSuffix}'
  scope:resourceGroup(subscriptionId, sessionHostResourceGroupName)
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
    resourceGroups
  ]
}

module rbacPermissionAzureAutomationAccountRg 'modules/rbacPermissions.bicep' = {
  name: 'rbac-automationAccount-deployment-${deploymentNameSuffix}'
  scope:resourceGroup(subscriptionId, ResourceGroups[0])
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
    resourceGroups
  ]
}

module getImageVersionlogicApp 'modules/logicappGetImageVersion.bicep' = {
  name: 'getImageVersionlogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[1])
  params: {
    startTime: startTime
    cloud: cloud
    officeConnectionName: officeConnectionName
    subscriptionId: subscriptionId
    emailContact: emailContact
    workflows_GetImageVersion_name: workflows_GetImageVersion_name
    automationAccountConnectionName: automationAccountConnectionName
    location: location
    state: state
    recurrenceFrequency: recurrenceFrequency
    recurrenceType: recurrenceType
    recurrenceInterval: recurrenceInterval
    automationAccountName: automationAccountName
    automationAccountLocation: automationAccount.outputs.aaLocation
    automationAccountResourceGroup: resourceGroups[0].name
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    getRunbookScheduleRunbookName: runbookScheduleRunbookName
    getRunbookGetSessionHostVm: runbookGetSessionHostVm
    getGetMarketPlaceImageVersion: runbookMarketPlaceImageVersion
    waitForRunBook: waitForRunBook
    hostPoolName: hostPoolName
    identityType: identityType
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
    o365Connection
    storageAccount
    resourceGroups
  ]
}

module getBlobUpdateLogicApp 'modules/logicAppGetBlobUpdate.bicep' = {
  name: 'getBlobUpdateLogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, ResourceGroups[1])
  params: {
    location: location
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    automationAccountName: automationAccountName
    automationAccountResourceGroup: resourceGroups[0].name
    blobConnectionName: blobConnectionName
    identityType: identityType
    state: state
    schema: schema
    contentVersion: contentVersion
    connectionType: connectionType
    triggerFrequency: triggerFrequency
    triggerInterval: triggerInterval
    storageAccountName: storageAccountName
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
    resourceGroups
  ]
}
