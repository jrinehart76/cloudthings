# Enable-VmBackup -RecoveryServicesVaultName '<name>'
param (
    #$ResourceGroupName,
    $RecoveryServicesVaultName,
    $Throttle = 5
)

$Jobs = @()

$EnableBackupPolicyJob = {
    param (
        $VM
    )
    $DefaultBackupPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"
    Enable-AzRecoveryServicesBackupProtection `
        -Policy $DefaultBackupPolicy `
        -Name $VM.Name `
        -ResourceGroupName $VM.ResourceGroupName
}

$VMs = Get-AzVM -Status
$Vault = Get-AzRecoveryServicesVault -Name $RecoveryServicesVaultName
Set-AzRecoveryServicesVaultContext -Vault $Vault
$BackupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType 'AzureVM' -Status 'Registered'

ForEach ($VM in $VMs) {
    If ($VM.Location -eq $Vault.Location) {
        if (!($BackupContainers | Where-Object { $_.FriendlyName -eq $VM.Name })) {
            $RunningJobs = $Jobs | Where-Object { $_.State -eq 'Running' }
            if ($RunningJobs.Count -ge $Throttle) {
                Write-Output "Max job queue of ${Throttle} reached. Please wait..."
                $RunningJobs | Wait-Job -Any | Out-Null
            }
            Write-Output "[$($VM.Name)] Default backup policy is not enabled. Starting job..."
            $Jobs += Start-Job -ScriptBlock $EnableBackupPolicyJob -ArgumentList $VM
        }
        else {
            Write-Output "[$($VM.Name)] Backup item already exists for the default policy."
        }   
    }
    else {
        Write-Output "[$($VM.Name)] is not in the same region as vault [$($Vault.Name)]"
    }
}

if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs | Receive-Job
$Jobs | Remove-Job