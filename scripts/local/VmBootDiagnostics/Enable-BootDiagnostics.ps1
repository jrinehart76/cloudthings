
# Enable-BootDiagnostics -ResourceGroupName 'rg-int' -StorageAccountName 'prdstgrmvmdiag01'

param (
    $ResourceGroupName,
    $StorageAccountName,
    $Throttle = 5
)

$Jobs = @()

$StorageAccount = Get-AzStorageAccount -ErrorAction 'SilentlyContinue' | Where-Object {$_.StorageAccountName -eq $StorageAccountName}

# Check if storage account exists
if ($StorageAccount) {
    Write-Output "${StorageAccountName} storage account exists. Proceeding..."
} else {
    Write-Error "${StorageAccountName} storage account doesn't exist. Please verify the storage account exists within your subscription."
    return
}

$EnableBootDiagnostics = {
    param (
        $Machine,
        $StorageAccount
    )
    $Resource = Get-AzResource -ResourceName $Machine.Name -ResourceGroupName $Machine.ResourceGroupName -ExpandProperties
    $Resource.Properties.diagnosticsProfile.bootDiagnostics.enabled = 'True'
    $Resource.Properties.diagnosticsProfile.BootDiagnostics.storageUri = $storageaccount.PrimaryEndpoints.Blob
    $Resource | Set-AzResource -Force
    
    # for some miraculous reason, this doesn't work
    # $Machine = Get-AzVM -ResourceId $Machine.Id
    # Set-AzVMBootDiagnostic -VM $Machine -Enable -StorageAccountName $StorageAccount.StorageAccountName -ResourceGroupName $StorageAccount.ResourceGroupName
}

$Machines = Get-AzVM -ResourceGroupName $ResourceGroupName -Status

ForEach ($Machine in $Machines) {
    if (!$Machine.DiagnosticsProfile.BootDiagnostics.Enabled) {
        $RunningJobs = $Jobs | Where-Object {$_.State -eq 'Running'}

        if ($RunningJobs.Count -ge $Throttle) {
            Write-Output "Max job queue of ${Throttle} reached. Please wait..."
            # block until any running job finishes
            $RunningJobs | Wait-Job -Any | Out-Null
        }

        Write-Output "[$($Machine.Name)] Boot diagnostics are not installed. Starting job..."
        $Jobs += Start-Job -ScriptBlock $EnableBootDiagnostics -ArgumentList $Machine,$StorageAccount
    } else {
        Write-Output "[$($Machine.Name)] Boot diagnostics are already enabled."
    }
}
if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs | Receive-Job
$Jobs | Remove-Job
