param subscriptionId string = 'f4972a61-1083-4904-a4e2-a790107320bf'
param workflows_GetBlobUpdate_name string = 'GetBlobUpdate6'
param automationAccountConnectionName string = 'azureautomation-7'
param automationAccountResourceGroup string = 'avdtest'
param automationAccountName string = 'avdtest'
param blobConnectionName string = 'azureblob-5'
param location string = 'usgovvirginia'
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
param runbookNewHostPoolRipAndReplace string = 'New-HostPoolRipAndReplace'
param runbookGetRunBookSchedule string = 'Get-RunBookSchedule'
param runbookGetSessionHostVirtualMachine string = 'Get-SessionHostVirtualMachine'

resource workflows_GetBlobUpdate_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GetBlobUpdate_name
  location: location
  identity: {
    type:  identityType
  }
  properties: {
    state: state
    definition: {
      '$schema': schema
      contentVersion: contentVersion
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: connectionType
        }
      }
      triggers: {
        'When_a_blob_is_added_or_modified_(properties_only)_(V2)': {
          recurrence: {
            frequency: triggerFrequency
            interval: triggerInterval
          }
          evaluatedRecurrence: {
            frequency: triggerFrequency
            interval: triggerInterval
          }
          splitOn: '@triggerBody()'
          metadata: {
            'container': '/${container}'
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${container}\'))}/triggers/batch/onupdatedfile'
            queries: {
              checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
              folderId: '/${container}'
              maxFileCount: maxFileCount
            }
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Create_job_2: {
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
                path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs'
                queries: {
                  runbookName: runbookGetSessionHostVirtualMachine
                  wait: true
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
            Create_job_3: {
              runAfter: {
                Parse_JSON_2: [
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
                method: 'put'
                path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs'
                queries: {
                  runbookName: runbookNewHostPoolRipAndReplace
                  wait: true
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
            Get_job_output_2: {
              runAfter: {
                Create_job_2: [
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
                path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Create_job_2\')?[\'properties\']?[\'jobId\'])}/output'
                queries: {
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
            Parse_JSON_2: {
              runAfter: {
                Get_job_output_2: [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'Get_job_output_2\')'
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
          }
          runAfter: {
            Parse_JSON: [
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
                  '@body(\'Parse_JSON\')?[\'ScheduleFound\']'
                  false
                ]
              }
            ]
          }
          type: 'If'
        }
        Create_job: {
          runAfter: {
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
            path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs'
            queries: {
              runbookName: runbookGetRunBookSchedule
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_job_output: {
          runAfter: {
            Create_job: [
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
            path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Create_job\')?[\'properties\']?[\'jobId\'])}/output'
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Parse_JSON: {
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
                ScheduleFound: {
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
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${automationAccountConnectionName}'
            connectionName: automationAccountConnectionName
            connectionProperties: {
            }
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureautomation'
          }
          azureblob: {
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${blobConnectionName}'
            connectionName: blobConnectionName
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
          }
        }
      }
    }
  }
}
