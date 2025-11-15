<#
This is a script that will:
- Create managed disks from disk snapshots located in the SAP subscription
- Remove the default disks that are rolled by the VM template
- Attach the disks using the LUNs required
#>
param (
    [string]
    [parameter(Mandatory=$true)]
    $ResourceGroupName,
    [string]
    [parameter(Mandatory=$true)]
    $SubscriptionName,
    [string]
    [parameter(Mandatory=$true)]
    $StorageAccountName,
    [string]
    $ServerNameSearchString = "EWD1"
)
#Select-AzureRMSubscription -SubscriptionName SAP
#$snapshots = Get-AzureRmSnapshot -ResourceGroupName "RG-AM-EastUS-SAP-NonProd-Compute" | ? { $_.Name -like "*EWM*" -and $_.Name -notlike "*-os.*" }

Select-AzureRMSubscription -SubscriptionName $SubscriptionName
$vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
$storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$snapshots = $storageAcct | Get-AzureStorageContainer -Name vhds | Get-AzureStorageBlob

foreach($vm in $vms){
    $vm | Stop-AzureRmVM -Verbose -Force
    Remove-AzureRmVmDataDisk -VM $vm -Name "Disk-$($vm.Name)-Data-LUN0"
    $vm | Update-AzureRmVM | Out-Null
    $serverType = "ewat"
    if($vm.Name -like "*$($ServerNameSearchString)*"){
        $serverType = "ewdt"
    }
    Write-Output "Removed data disk from $($vm.Name)."
    $snapshots
    foreach($snapshot in $snapshots.Where({ $_.Name -like "*$($serverType)*"})) {
        Write-Output $snapshot.Id
        Write-Output $snapshot.Location
        $lun = 0
        switch($snapshot.Name) {
            "ewdt01-saplog01.snap.vhd" { $lun = 1 }
            "ewdt01-sapdata01.snap.vhd" { $lun = 2 }
        }
        $diskname = $snapshot.Name.Replace("vhd","LUN$($lun)")
        # Check first to make sure it's not already done
        $chk = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $diskname -ErrorAction SilentlyContinue
        if($chk -ne $null -and $chk.ManagedBy -eq $vm.Id) {
            Write-Output "Disk $($diskname) already exists and has been attached."
        } else {
           Write-Output "Creating new managed disk from snapshot $($snapshot.Name)..."
           $diskConfig = New-AzureRmDiskConfig -CreateOption Import -AccountType StandardSSD_LRS -Location $vm.Location -SourceUri "https://$($StorageAccountName).blob.core.windows.net/vhds/$($snapshot.Name)" -StorageAccountId $storageAcct.Id
            $disk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $ResourceGroupName -DiskName $diskname -Verbose
            Add-AzureRmVmDataDisk -VM $vm -Lun $lun -CreateOption Attach -ManagedDiskId $disk.Id -Verbose
            $vm | Update-AzureRmVM -Verbose 
        }
        
    }
    $vm | Start-AzureRmVM -Verbose
}


