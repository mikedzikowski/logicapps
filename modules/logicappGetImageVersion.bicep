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
param hostPoolName string
param identityType string
param emailContact string
param officeConnectionName string
param cloud string
param startTime string

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
        Check_for_Existing_Schedule: {
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
          Schedule_and_NewImage_Condition: {
            actions: {
              Approval_Condition: {
                actions: {
                  Create_schedule_for_host_pool_rip_and_replace: {
                    runAfter: {
                    }
                    type: 'ApiConnection'
                    inputs: {
                      body: {
                        properties: {
                          parameters: {
                            AutomationAccountName: automationAccountName
                            ResourceGroupName: automationAccountResourceGroup
                            ScheduleName: 'NewScheduelRipAndReplace'
                            StartTime: startTime
                            environment: cloud
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
                        runbookName: 'New-AutomationSchedule'
                        wait: true
                        'x-ms-api-version': '2015-10-31'
                      }
                    }
                  }
                }
                runAfter: {
                  Send_approval_email: [
                    'Succeeded'
                  ]
                }
                else: {
                  actions: {
                    Terminate_2: {
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
                        '@body(\'Send_approval_email\')?[\'SelectedOption\']'
                        'Approve'
                      ]
                    }
                  ]
                }
                type: 'If'
              }
              Send_approval_email: {
                runAfter: {
                }
                type: 'ApiConnectionWebhook'
                inputs: {
                  body: {
                    Message: {
                      Body: 'Virtual Machine: @{body(\'Parse_Session_Host_VM_and_RG\')?[\'productionVM\']}\n\n\nNew Image Status:  @{body(\'Parse_image_version\')?[\'NewImageFound\']}\n\n\nPlease approve schedule for "Rip and Replace" of AVD enviroment. \n'
                      HideHTMLMessage: true
                      Importance: 'High'
                      Options: 'Approve, Reject'
                      ShowHTMLConfirmationDialog: false
                      Subject: 'Approval Requested - New Image Found for AVD Environment. Please Approve or Reject Creating Automated Schedule for Updating AVD Environment'
                      To: emailContact
                    }
                    NotificationUrl: '@{listCallbackUrl()}'
                  }
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                    }
                  }
                  path: '/approvalmail/$subscriptions'
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
        Get_Job_Output: {
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
        Get_Job_Output_of_Marketplace_Image_Version: {
          runAfter: {
            Get_Marketplace_Image_Version: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Marketplace_Image_Version\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Marketplace_Image_Version: {
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
        'Get_Output_from_Runbook_Get-RunBookSchedule': {
          runAfter: {
            Check_for_Existing_Schedule: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Check_for_Existing_Schedule\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Parse_Schedule: {
          runAfter: {
            'Get_Output_from_Runbook_Get-RunBookSchedule': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Output_from_Runbook_Get-RunBookSchedule\')'
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
            Get_Job_Output: [
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
            Get_Job_Output_of_Marketplace_Image_Version: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Job_Output_of_Marketplace_Image_Version\')'
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
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${automationAccountConnectionName}'
            connectionName: automationAccountConnectionName
            connectionProperties:{
            authentication: {
              type: 'ManagedServiceIdentity'
            }
          }
            id: concat('/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${automationAccountLocation}/managedApis/azureautomation')
          }
          office365: {
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${officeConnectionName}'
            connectionName: officeConnectionName
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${automationAccountLocation}/managedApis/office365'
          }
        }
      }
    }
  }
}
output imagePrincipalId string = workflows_GetImageVersion_name_resource.identity.principalId
