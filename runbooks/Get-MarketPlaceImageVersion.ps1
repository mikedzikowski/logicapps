
[CmdletBinding()]
param (

    [parameter(mandatory = $true)]$vmName,
	[parameter(mandatory = $true)]$resourceGroupName
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