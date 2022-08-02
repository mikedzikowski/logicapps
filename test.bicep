param workflows_GetImageVersionLogicApp_name string = 'GetImageVersionLogicApp'
param connections_azureautomation_externalid string = '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/resourceGroups/rg-staging-va-la/providers/Microsoft.Web/connections/azureautomation'
param connections_office365_externalid string = '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/resourceGroups/rg-staging-va-la/providers/Microsoft.Web/connections/office365'

resource workflows_GetImageVersionLogicApp_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GetImageVersionLogicApp_name
  location: 'usgovvirginia'
  tags: {
    Environment: 'Production'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Day'
            interval: 1
          }
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Check_for_existing_Schedule: {
          runAfter: {
            Parse_Session_Host_VM_and_RG: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  AutomationAccountName: 'aa-staging-va'
                  ResourceGroupName: 'rg-staging-va-aa'
                  runbookName: 'New-HostPoolRipAndReplace'
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs'
            queries: {
              runbookName: 'Get-RunBookSchedule'
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Condition: {
          actions: {

          }
          runAfter: {
            Parse_image_version: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Terminate: {
                runAfter: {
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Cancelled'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Parse_Schedule\')?[\'ScheduleFound\']'
                  false
                ]
              }
              {
                equals: [
                  '@body(\'Parse_image_version\')?[\'NewImageFound\']'
                  true
                ]
              }
            ]
          }
          type: 'If'
        }
        Get_Session_Host_VM: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  hostpoolName: 'ProdMirror'
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs'
            queries: {
              runbookName: 'Get-SessionHostVirtualMachine'
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_job_output: {
          runAfter: {
            Get_Session_Host_VM: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs/@{encodeURIComponent(body(\'Get_Session_Host_VM\')?[\'properties\']?[\'jobId\'])}/output'
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_job_output_of_marketplace_image_version: {
          runAfter: {
            Get_marketplace_image_version: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs/@{encodeURIComponent(body(\'Get_marketplace_image_version\')?[\'properties\']?[\'jobId\'])}/output'
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_marketplace_image_version: {
          runAfter: {
            Parse_Schedule: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  ResourceGroupName: '@body(\'Parse_Session_Host_VM_and_RG\')?[\'productionVmRg\']'
                  VMName: '@body(\'Parse_Session_Host_VM_and_RG\')?[\'productionVm\']'
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs'
            queries: {
              runbookName: 'Get-MarketPlaceImageVersion'
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        'Get_output_from_runbook_Get-RunBookSchedule': {
          runAfter: {
            Check_for_existing_Schedule: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-staging-va-aa\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-staging-va\')}/jobs/@{encodeURIComponent(body(\'Check_for_existing_Schedule\')?[\'properties\']?[\'jobId\'])}/output'
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Parse_Schedule: {
          runAfter: {
            'Get_output_from_runbook_Get-RunBookSchedule': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_output_from_runbook_Get-RunBookSchedule\')'
            schema: {
              properties: {
                ScheduleFound: {
                  type: 'boolean'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_Session_Host_VM_and_RG: {
          runAfter: {
            Get_job_output: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_job_output\')'
            schema: {
              properties: {
                productionVM: {
                  type: 'string'
                }
                productionVmRg: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_image_version: {
          runAfter: {
            Get_job_output_of_marketplace_image_version: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_job_output_of_marketplace_image_version\')'
            schema: {
              properties: {
                NewImageFound: {
                  type: 'boolean'
                }
              }
              type: 'object'
            }
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureautomation: {
            connectionId: connections_azureautomation_externalid
            connectionName: 'azureautomation'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/providers/Microsoft.Web/locations/usgovvirginia/managedApis/azureautomation'
          }
          office365: {
            connectionId: connections_office365_externalid
            connectionName: 'office365'
            id: '/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/providers/Microsoft.Web/locations/usgovvirginia/managedApis/office365'
          }
        }
      }
    }
  }
}
