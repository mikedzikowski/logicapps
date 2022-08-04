[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$AutomationAccountName,
    [parameter(mandatory = $true)]$ResourceGroupName,
    [parameter(mandatory = $true)]$RunbookName,
	[parameter(mandatory = $true)]$Environment,
    [parameter(mandatory = $true)]$ScheduleName,
    [parameter(mandatory = $true)]$DayOfWeek,
    [parameter(mandatory = $true)]$DayOfWeekOccurrence,
    [parameter(mandatory = $true)]$StartTime,
    [parameter(mandatory = $true)]$HostPoolName
)

Connect using a Managed Service Identity
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
New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $StartTime -ResourceGroupName $ResourceGroupName -TimeZone $TimeZone -DayOfWeek $DayOfWeek -DayOfWeekOccurrence $DayOfWeekOccurrence -MonthInterval 1

Start-Sleep 10

$params = @{"HostPoolName" = $HostPoolName;}
# Register Automation Schedule to Runbook
Register-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $RunbookName -ScheduleName $ScheduleName -Parameters $params