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
param identityType string
param emailContact string
param officeConnectionName string
param startTime string
param dayOfWeek string
param dayOfWeekOccurrence string
param cloud string
param tenantId string
param subscriptionId string
param hostPoolName string
param templateSpecId string
param keyVaultName string
param prodHostPoolName string

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
        Check_for_Exisiting_Runbook_Schedule_for_Hostpool_Validation_Environment: {
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
                  Environment: cloud
                  HostpoolName: hostPoolName
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
        Condition_Check_for_Runbook_Schedule_and_Image_Version_on_Validation_Environment: {
          actions: {
            Condition_Check_for_Approval_Selection_in_Email: {
              actions: {
                Condition: {
                  actions: {
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
                              ScheduleName: '${prodHostPoolName}-ScheduleForRipAndReplace'
                              StartTime: startTime
                              DayOfWeek: dayOfWeek
                              DayOfWeekOccurrence: dayOfWeekOccurrence
                              environment: cloud
                              runbookName: runbookNewHostPoolRipAndReplace
                              HostPoolName: prodHostPoolName
                              TenantId: tenantId
                              TemplateSpecId: templateSpecId
                              SubscriptionId: subscriptionId
                              KeyVault: keyVaultName
                            }
                          }
                        }
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
                          }
                        }
                        method: 'put'
                        path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-fs-peo-va-d-management-01\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-fs-peo-va-d-00-rar\')}/jobs'
                        queries: {
                          runbookName: 'New-AutomationSchedule'
                          wait: true
                          'x-ms-api-version': '2015-10-31'
                        }
                      }
                    }
                  }
                  runAfter: {
                    Send_Approval_Email_for_Rip_and_Replace_in_Production_AVD_environment: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      Terminate_3: {
                        runAfter: {
                        }
                        type: 'Terminate'
                        inputs: {
                          runStatus: 'Failed'
                        }
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@body(\'Send_Approval_Email_for_Rip_and_Replace_in_Production_AVD_environment\')?[\'SelectedOption\']'
                          'Approve'
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
                Create_Schedule_for_Hostpool_Rip_and_Replace_on_Validation_Environment: {
                  runAfter: {
                  }
                  type: 'ApiConnection'
                  inputs: {
                    body: {
                      properties: {
                        parameters: {
                          AutomationAccountName: automationAccountName
                          ResourceGroupName: automationAccountResourceGroup
                          ScheduleName: '${hostPoolName}-ScheduleForRipAndReplace'
                          StartTime: startTime
                          DayOfWeek: dayOfWeek
                          DayOfWeekOccurrence: dayOfWeekOccurrence
                          environment: cloud
                          runbookName: runbookNewHostPoolRipAndReplace
                          HostPoolName: hostPoolName
                          TenantId: tenantId
                          TemplateSpecId: templateSpecId
                          SubscriptionId: subscriptionId
                          KeyVault: keyVaultName
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
                Send_Approval_Email_for_Rip_and_Replace_in_Production_AVD_environment: {
                  runAfter: {
                    Wait_2_Hours_for_Validation_Environment_Verification: [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnectionWebhook'
                  inputs: {
                    body: {
                      Message: {
                        HideHTMLMessage: true
                        Importance: 'High'
                        Options: 'Approve, Reject'
                        SelectionText: 'Approval Requested -Deployment for Rip and Replace in Production AVD environment'
                        ShowHTMLConfirmationDialog: false
                        Subject: 'Approval Requested -Deployment for Rip and Replace in Production AVD environment.'
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
                Wait_2_Hours_for_Validation_Environment_Verification: {
                  runAfter: {
                    Create_Schedule_for_Hostpool_Rip_and_Replace_on_Validation_Environment: [
                      'Succeeded'
                    ]
                  }
                  type: 'Wait'
                  inputs: {
                    interval: {
                      count: 2
                      unit: 'Hour'
                    }
                  }
                }
              }
              runAfter: {
                Send_Approval_Email_for_Rip_and_Replace_in_Validation_Environment: [
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
                      '@body(\'Send_Approval_Email_for_Rip_and_Replace_in_Validation_Environment\')?[\'SelectedOption\']'
                      'Approve'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Send_Approval_Email_for_Rip_and_Replace_in_Validation_Environment: {
              runAfter: {
              }
              type: 'ApiConnectionWebhook'
              inputs: {
                body: {
                  Message: {
                    Body: 'Hostpool: @{body(\'Parse_Session_Host_VM_and_RG\')?[\'hostPool\']}\n\n\nNew Image Version:  @{body(\'Parse_image_version\')?[\'ImageVersion\']}\n\n\nPlease approve schedule on the ${dayOfWeekOccurrence} ${dayOfWeek} of the Month @ ${startTime} for "rip and replace" of @{body(\'Parse_Session_Host_VM_and_RG\')?[\'hostPool\']} AVD enviroment. \n'
                    HideHTMLMessage: true
                    Importance: 'High'
                    Options: 'Approve, Reject'
                    ShowHTMLConfirmationDialog: false
                    Subject: 'New Image Version Found for AVD Hostpool Environment - @{body(\'Parse_Session_Host_VM_and_RG\')?[\'hostPool\']}. Please Approve or Reject Creating Automated Schedule for Updating AVD Environment'
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
        Get_Image_Version_of_Sessionhost_in_Validation_Environment: {
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
                  Environment: cloud
                }
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/subscriptions/@{encodeURIComponent(\'f4972a61-1083-4904-a4e2-a790107320bf\')}/resourceGroups/@{encodeURIComponent(\'rg-fs-peo-va-d-management-01\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'aa-fs-peo-va-d-00-rar\')}/jobs'
            queries: {
              runbookName: getGetMarketPlaceImageVersion
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Job_Output: {
          runAfter: {
            Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Job_Output_of_Marketplace_Image_Version: {
          runAfter: {
            Get_Image_Version_of_Sessionhost_in_Validation_Environment: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Image_Version_of_Sessionhost_in_Validation_Environment\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        'Get_Output_from_Runbook_Get-RunBookSchedule': {
          runAfter: {
            Check_for_Exisiting_Runbook_Schedule_for_Hostpool_Validation_Environment: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  hostpoolName: hostPoolName
                  Environment: cloud
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
                hostPool: {
                  type: 'string'
                }
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
                ImageVersion: {
                  type: 'string'
                }
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
