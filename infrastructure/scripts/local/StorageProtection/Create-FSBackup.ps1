Param (
    [Parameter(Mandatory = $true)]
    [String] $rsvName,
    [Parameter(Mandatory = $true)]
    [Int] $vaultRetention
)
<#
##This section is for azure automation runbooks
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
} Catch {
    if (!$Connection)
    {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#>
#Get the current date
$currentDate = Get-Date

#Set the retention of the snapshot
$recoveryRetention = $currentDate.AddDays($vaultRetention)

#Output details
Write-Output "Snapshots will be kept for [$($vaultRetention)] days on RSV [$($rsvName)]"
Write-Output "Snapshots will expire on [$($recoveryRetention)]"

#Set the vault context
$vault = Get-AzRecoveryServicesVault -Name $rsvName
Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop -WarningAction SilentlyContinue
Write-Output "Vault context is set to [$($vault.Name)]"

#Get the containers in the vault
$containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage
Write-Output "Number of containers found [$($containers.Count)] in [$($vault.Name)]"

foreach ($container in $containers) {
    $fileshares = Get-AzRecoveryServicesBackupItem -WorkloadType AzureFiles -Container $container
    if ($fileshares) {
        Write-Output "Starting fileshare backup on [$($fileshares.Name)] in vault [$($vault.Name)]"
        Backup-AzRecoveryServicesBackupItem -Item $fileshares -ExpiryDateTimeUTC $recoveryRetention
    }
    else {
        Write-Output "No fileshares found in container [$($container.FriendlyName)]"
    }       
}