<#
    .DESCRIPTION
    
       This script loops through all VMs with Get-AzVM, and for each VM it checks backup status with  Get-AzRecoveryServicesBackupStatus
    .PREREQUISITES

    Need to install and import Az.RecoveryServices for Get-AzRecoveryServicesBackupStatus
    Install-Module -Name Az.RecoveryServices -RequiredVersion 1.4.5 -Scope CurrentUser
      
    .EXAMPLE
    .TO-DO
      
    .NOTES
    This script works Sub by Sub basis!
    To switch subscriptions: Set-AzContext -subscriptioid " "

        AUTHOR(s):Erlin Tego
    .VERSION
    .CHANGELOG  
#>

Param()

$vms = @()
$output = @()
$subList = Get-AzSubscription

foreach ($sub in $subList) {
    Set-AzContext -Subscription $sub.Name
    $vms = Get-AzVM
    foreach ($vm in $vms) {
        $status = Get-AzRecoveryServicesBackupStatus -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type AzureVM
        Write-Output "Getting backup status for [$($vm.Name)]"
        $output = $_.$vms | ForEach-Object { 
            [PSCustomObject]@{ 
                "VM Name"        = $vm.Name
                "Resource Group" = $vm.ResourceGroupName
                "Backup Status"  = $status.BackedUp
                "Vault"          = $status.VaultId -join ','
            }
        }
        $output | Export-Csv  -Path "$([environment]::GetFolderPath("mydocuments"))\BackupStatusAuditOnDemand.csv" -delimiter ";" -Append -force -notypeinformation 
    }
    Write-Output ""
}