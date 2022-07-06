param connection_azureautomation_name string
param tenantId string
param subscriptionId string
param location string
param clientId string
@secure()
param clientSecret string
param displayName string
param iconUri string = 'https://connectoricons-prod.azureedge.net/releases/v1.0.1538/1.0.1538.2619/azureautomation/icon.png'
param apiType string = 'Microsoft.Web/locations/managedApis'
param description string = 'Azure Automation provides tools to manage your cloud and on-premises infrastructure seamlessly.'
param brandColor string = '#56A0D7'

resource connection_azureautomation_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connection_azureautomation_name
  location: location
  kind: 'V1'
  properties: {
    displayName: displayName
    statuses: [
      {
        'status': 'Connected'
      }
    ]
    customParameterValues: {
    }
    nonSecretParameterValues: {
    }
    parameterValues: {
      'token:TenantId': tenantId
      'token:clientId': clientId
      'token:grantType': 'client_credentials'
      'token:clientSecret': clientSecret
    }
    api: {
      name: connection_azureautomation_name
      displayName: displayName
      description: description
      iconUri: iconUri
      brandColor: brandColor
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/usgovvirginia/managedApis/azureautomation'
      type: apiType
    }
    testLinks: []
  }
}
