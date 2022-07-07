[CmdletBinding()]
param (

    [parameter(mandatory = $true)]$hostpoolName
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


# Getting the hostpool first
$hostpool = Get-AzWvdHostPool | Where-Object { $_.Name -eq $hostpoolname }

if ($null -eq $hostpool)
{
    "Hostpool $hostpoolname not found"
    exit;
}


$hostpoolRg = ($hostpool).id.split("/")[4]

# Select a VM in hostpool
$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $hostpoolRg -HostPoolName $hostpoolName
$existingSessionHost = ($sessionHosts.Name.Split("/")[-1]).Split(".")[0]
$productionVirtualMachine = Get-AzVM -Name $existingSessionHost 

$objOut = [PSCustomObject]@{
    productionVm = $productionVirtualMachine.Name
	productionVmRg = $productionVirtualMachine.ResourceGroupName
}

Write-Output ( $objOut | ConvertTo-Json)