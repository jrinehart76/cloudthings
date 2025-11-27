
$Jobs = @()

$RunbookName = 'xm_Enable_Backups'
$AutomationAccountName = 'rmauto'
$AutomationAccountResourceGroupName = 'rg-oms'
$RecoveryServicesVaultName = 'prd-recovery'
$ResourceGroupNames = @('rg-int', 'rg-caleb')

$Runbooks = @(
    @{
        Name='xm_Enable_Backups'
        Parameters=@{
            'RecoveryServicesVaultName'=$RecoveryServicesVaultName
            'ResourceGroupName'=$ResourceGroupName
        }
    }
)

ForEach ($Runbook in $Runbooks) {
    ForEach ($ResourceGroupName in $ResourceGroupNames) {
        $Jobs += Start-AzAutomationRunbook `
            -Name $Runbook.Name `
            -Parameters $Runbook.Parameters `
            -ResourceGroupName $AutomationAccountResourceGroupName `
            -AutomationAccountName $AutomationAccountName
    }
}

$JobsTotal = $Jobs.Count

$JobStatus = Get-AzAutomationJob `
    -RunbookName $RunbookName `
    -ResourceGroupName $AutomationAccountResourceGroupName `
    -AutomationAccountName $AutomationAccountName | Where-Object {$_.JobId -in $Jobs.JobId}

While ($JobStatus.Status -Contains 'New' -or $JobStatus.Status -Contains 'Running') {
    $JobStatus = Get-AzAutomationJob `
        -RunbookName $RunbookName `
        -ResourceGroupName $AutomationAccountResourceGroupName `
        -AutomationAccountName $AutomationAccountName | Where-Object {$_.JobId -in $Jobs.JobId}
    $JobsComplete = $JobStatus | Where-Object {$_.Status -Contains 'Completed'}
    Write-Progress -Activity "Enabling backups for VMs in resource groups: $($ResourceGroupNames -Join ',')" -Status "$($JobsComplete.Count) / ${JobsTotal} jobs complete" -PercentComplete (($JobsComplete.Count * 100) / $JobsTotal)
}