
[CmdletBinding()]
param (

    [parameter(mandatory = $true)]$automationAccountName,
	[parameter(mandatory = $true)]$resourceGroupName,
	[parameter(mandatory = $true)]$runbookName
)


$connectionName = "AzureRunAsConnection"

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -EnvironmentName AzureUSGovernment | Out-Null
 }
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

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

