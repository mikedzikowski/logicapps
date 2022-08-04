[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$HostpoolName
)

Write-Verbose $HostpoolName