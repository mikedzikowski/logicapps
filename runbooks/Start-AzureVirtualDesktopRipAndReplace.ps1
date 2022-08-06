[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$HostPoolName,

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$TemplateSpecId,

    [Parameter(Mandatory)]
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

Disable-AzContextAutosave `
    –Scope Process

Connect-AzAccount `
    -Environment $Environment `
    -Identity `
    -Subscription $SubscriptionId `
    -Tenant $TenantId

# Get the host pool's info
$HostPool = Get-AzResource -ResourceType 'Microsoft.DesktopVirtualization/hostpools' | Where-Object {$_.Name -eq $HostPoolName}
$HostPoolResourceGroup = $HostPool.ResourceGroupName
$HostPoolInfo = Get-AzWvdHostPool -ResourceGroupName $HostPoolResourceGroup -Name $HostPoolName
$AppGroupResourceId = $HostPoolInfo.ApplicationGroupReference[-1]
$SecurityPrincipalIds = (Get-AzRoleAssignment -Scope $AppGroupResourceId -RoleDefinitionName 'Desktop Virtualization User').ObjectId
$HostPoolTags = $HostPool.Tags
$Configuration = $HostPoolTags.AvdConfiguration | ConvertFrom-Json
$SoftwareSettings = $HostPoolTags.AvdSoftware | ConvertFrom-Json

# Get details for deployment params
$Params = {
    AddOrReplace = $true
    DeployAip = $SoftwareSettings.DeployAip
    DeployAppMaskingRules = $SoftwareSettings.DeployAppMaskingRules
    DeployProjectVisio = $SoftwareSettings.DeployProjectVisio
    DisaStigCompliance = $SoftwareSettings.DisaStigCompliance
    DiskSku = $Configuration.DiskSku
    DomainName = $Configuration.DomainName
    DomainServices = $Configuration.DomainServices
    Environment = $HostPoolName.Split('-')[4]
    HostPoolType = $HostPoolInfo.HostPoolType.ToString() + ' ' + $HostPoolInfo.LoadBalancerType.ToString()
    ImageOffer = $Configuration.Image.Split(':')[1]
    ImagePublisher = $Configuration.Image.Split(':')[0]
    ImageSku = $Configuration.Image.Split(':')[2]
    ImageVersion = $Configuration.Image.Split(':')[3]
    LogAnalyticsWorkspaceId = $HostPoolTags.AvdMonitoring
    MissionOwnerShortName = $HostPoolName.Split('-')[2]
    RecoveryServices = $Configuration.RecoveryServices
    ScreenCaptureProtection = $SoftwareSettings.ScreenCaptureProtection
    ScriptContainerUri = $HostPoolTags.AvdContainer
    SecurityPrincipalIds = $SecurityPrincipalIds
    SessionHostOuPath = $HostPoolTags.AvdOuPath
    StampIndex = $HostPoolName.Split('-')[5].ToInt32($null)
    TenantShortName = $HostPoolName.Split('-')[1]
    VmSize = $Configuration.VmSize
}

# Get all session hosts
$SessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $HostPoolResourceGroup `
    -HostPoolName $HostPoolName

# Get the resource group for the session hosts
$SessionHostsResourceGroup = $SessionHosts[0].ResourceId.Split('/')[4]

# Put all session hosts in drain mode
foreach($SessionHost in $SessionHosts)
{
    Update-AzWvdSessionHost `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -Name $SessionHost.Id.Split('/')[-1] `
        -AllowNewSession:$false `
        | Out-Null
}

# Get all active sessions
$Sessions = Get-AzWvdUserSession `
    -ResourceGroupName $HostPoolResourceGroup `
    -HostPoolName $HostPoolName

# Send a message to any user with an active session
$Time = (Get-Date).ToUniversalTime().AddMinutes(15)
foreach($Session in $Sessions)
{
    $SessionHost = $Session.Id.split('/')[-3]
    $UserSessionId = $Session.Id.split('/')[-1]

    Send-AzWvdUserSessionMessage  `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -SessionHostName $SessionHost `
        -UserSessionId $UserSessionId `
        -MessageBody "Maintenance will begin in 15 minutes: $Time UTC. Please save your work and sign out. If you do not sign out within 15 minutes, your session will be terminated and you may lose your work." `
        -MessageTitle 'Upcoming Maintenance'
}

# Wait 15 minutes for all users to sign out
Start-Sleep -Seconds 900

# Force logout any leftover sessions
foreach($Session in $Sessions)
{
    $SessionHost = $Session.Id.split('/')[-3]
    $UserSessionId = $Session.Id.split('/')[-1]

    Remove-AzWvdUserSession  `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -SessionHostName $SessionHost `
        -Id $UserSessionId
}

# Remove the session hosts from the Host Pool
foreach($SessionHost in $SessionHosts)
{
    Remove-AzWvdSessionHost `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -Name $SessionHost.Id.Split('/')[-1] `
        | Out-Null
}

# Delete the resource group containing only the session hosts
Remove-AzResourceGroup `
    -Name $SessionHostsResourceGroup `
    -Force

# Deploy new session hosts to the host pool
New-AzSubscriptionDeployment `
    -Location $HostPool.Location `
    -Name $(Get-Date -F 'yyyyMMddHHmmss') `
    -TemplateSpecId $TemplateSpecId `
    @Params

# Remove Runbook Schedule
