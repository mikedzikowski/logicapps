[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$AutomationAccountName,
    [parameter(mandatory = $true)]$ResourceGroupName,
    [parameter(mandatory = $true)]$RunbookName,
    [parameter(mandatory = $true)]$ScheduleName,
    [parameter(mandatory = $true)]$StartTime,
    [parameter(mandatory = $true)]$DayOfWeek,
	[parameter(mandatory = $true)]$Environment
)

# Connect using a Managed Service Identity
try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment $Environment).context
}
catch
{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}

$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# Create Automation Schedule
$TimeZone = ([System.TimeZoneInfo]::Local).Id
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleName -DayOfWeek $DayOfWeek -StartTime $StartTime -ResourceGroupName $ResourceGroupName -TimeZone $TimeZone -OneTime

Start-Sleep 10

# Register Automation Schedule to Runbook
Register-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $RunbookName -ScheduleName $ScheduleName