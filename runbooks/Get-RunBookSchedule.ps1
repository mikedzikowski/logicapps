
[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$AutomationAccountName,
	[parameter(mandatory = $true)]$ResourceGroupName,
	[parameter(mandatory = $true)]$RunbookName
)

# Connect using a Managed Service Identity
try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment AzureUSGovernment).context
}
catch
{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}

$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

$schedule  = Get-AzAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -RunbookName $RunbookName

if ($schedule)
{
	$scheduleFound = $true
}
else
{
	$scheduleFound = $false
}


$objOut = [PSCustomObject]@{
    ScheduleFound = $scheduleFound
}

Write-Output ( $objOut | ConvertTo-Json)