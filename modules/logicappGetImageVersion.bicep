param subscriptionId string
param workflows_GetImageVersion_name string
param automationAccountConnectionName string
param location string
param state string
param recurrenceFrequency string
param recurrenceInterval int
param recurrenceType string
param automationAccountName string
param automationAccountResourceGroup string
param automationAccountLocation string
param runbookNewHostPoolRipAndReplace string
param getRunbookScheduleRunbookName string
param getRunbookGetSessionHostVm string
param getGetMarketPlaceImageVersion string
param waitForRunBook bool
param falseExpression bool
param trueExpression bool
param hostPoolName string
param identityType string


resource workflows_GetImageVersion_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GetImageVersion_name

  location: location
  identity: {
    type: identityType
  }
  properties: {
    state: state
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
            frequency: recurrenceFrequency
            interval: recurrenceInterval
          }
          evaluatedRecurrence: {
            frequency: recurrenceFrequency
            interval: recurrenceInterval
          }
          type: recurrenceType
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
                  AutomationAccountName: automationAccountName
                  ResourceGroupName: automationAccountResourceGroup
                  runbookName: runbookNewHostPoolRipAndReplace
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
            queries: {
              runbookName: getRunbookScheduleRunbookName
              wait: waitForRunBook
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Condition: {
          actions: {
            Create_rip_and_replace_job: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
                  }
                }
                method: 'put'
                path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
                queries: {
                  runbookName: runbookNewHostPoolRipAndReplace
                  wait: waitForRunBook
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
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
                  falseExpression
                ]
              }
              {
                equals: [
                  '@body(\'Parse_image_version\')?[\'NewImageFound\']'
                  trueExpression
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
                  hostpoolName: hostPoolName
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
            queries: {
              runbookName: getRunbookGetSessionHostVm
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Session_Host_VM\')?[\'properties\']?[\'jobId\'])}/output')
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_marketplace_image_version\')?[\'properties\']?[\'jobId\'])}/output')
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
            queries: {
              runbookName: getGetMarketPlaceImageVersion
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Check_for_existing_Schedule\')?[\'properties\']?[\'jobId\'])}/output')
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
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${automationAccountResourceGroup}/providers/Microsoft.Web/connections/${automationAccountConnectionName}'
            connectionName: automationAccountConnectionName
            authentication: {
              type: 'ManagedServiceIdentity'
          }
            id: concat('/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${automationAccountLocation}/managedApis/azureautomation')
          }
        }
      }
    }
  }
}
