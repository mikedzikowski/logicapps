param connection_azureautomation_name string
param tenantId string
param subscriptionId string
param location string
param clientId string
@secure()
param clientSecret string
param displayName string
param iconUri string
param apiType string
param description string
param brandColor string

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


