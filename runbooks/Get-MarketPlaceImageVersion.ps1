
[CmdletBinding()]
param (

    [parameter(mandatory = $true)]$vmName,
	[parameter(mandatory = $true)]$resourceGroupName
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


$hostpoolvm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

$versions = (Get-AzVMImage -Location $hostpoolvm.Location -PublisherName $hostpoolvm.StorageProfile.ImageReference.Publisher -Offer $hostpoolvm.StorageProfile.ImageReference.Offer -Sku $hostpoolvm.StorageProfile.ImageReference.Sku | Select-Object -Last 1).version

foreach ($version in $versions) {

    if ($version -gt $hostpoolvm.StorageProfile.ImageReference.ExactVersion)
    {
        $newImageFound = $true
    }
    else
    {
        $newImageFound = $false
    }
}

$objOut = [PSCustomObject]@{
    NewImageFound = $newImageFound
}

Write-Output ( $objOut | ConvertTo-Json)