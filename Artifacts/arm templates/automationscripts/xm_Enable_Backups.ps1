<#
    .DESCRIPTION
        Enables backups to Recovery Service vault to all VMs in subscription.

    .PREREQUISITES
        Must have existing AzureRunAsAccount
        Recovery Service vault must exist
        Machines must be in the same region as the vault

    .DEPENDENCIES
        Az.Accounts
        Az.Compute
        Az.RecoveryServices

    .TODO

    .NOTES
        AUTHOR: cherbison, jrinehart
        LASTEDIT: 2019.7.2

    .CHANGELOG

    .VERSION
        1.0.0
#>

##gather parameters
param (
    [Parameter(Mandatory = $True)]
    [string]$rsvName,

    [Parameter(Mandatory = $False)]
    [string]$rgName
)

#Connect as automation SPN goes here
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

##get a list of virtual machines
if ($rgName) {
    $VMs = Get-AzVM -ResourceGroupName $rgName
}
else {
    $VMs = Get-AzVM
}

##if no virtual machines found, return
if (!($VMs)) {
    Write-Error "No VMs found in subscription or resource group."
    return
}

##declare variables and assign values
$Vault = Get-AzRecoveryServicesVault -Name $rsvName
Set-AzRecoveryServicesVaultContext -Vault $Vault -WarningAction SilentlyContinue -ErrorAction Stop
$BackupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType 'AzureVM' -Status 'Registered'

##process backups for each virtual machine
ForEach ($VM in $VMs) {
    if ($VM.Location -eq $Vault.Location) {
        if (!($BackupContainers | Where-Object { $_.FriendlyName -eq $VM.Name })) {
            $DefaultBackupPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"
            Write-Output "Enabling backup on [$($VM.Name)] with default policy [$($DefaultBackupPolicy.Name)]."
            Enable-AzRecoveryServicesBackupProtection -Policy $DefaultBackupPolicy -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
        }
        else {
            Write-Output "[$($VM.Name)] backup already exists for the default policy."
        }
    }
    else {
        Write-Output "[$($VM.Name)] is not in the same region as vault [$($Vault.Name)]"
    }
}
