
[CmdletBinding()]
param (

    [parameter(mandatory = $true)]$automationAccountName,
	[parameter(mandatory = $true)]$resourceGroupName,
	[parameter(mandatory = $true)]$runbookName
)


# Connect using a Managed Service Identity
try {
    $AzureContext = (Connect-AzAccount -Identity -Environment AzureUSGovernment).context
}
catch{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}

$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

$schedule  = Get-AzAutomationScheduledRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -RunbookName $runbookName


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

