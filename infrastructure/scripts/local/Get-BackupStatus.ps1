$path = Convert-Path ".\Scripts\ResourceGraph"
$csvFile = "$($path)\VMBackup.csv"
$verboseOutput = $false

##################################
$subscription = "GCCS"
Set-AzureSubscriptionContext -Subscription $subscription -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

$subscriptions = Get-AzSubscription | select Id, Name
$output = @()
foreach ($resource in (Search-AzGraph -Query "resources | where type == 'microsoft.compute/virtualmachines' and resourceGroup !contains 'mc_rg'" -First 5000)) {
    Write-Output "$($resource.name)"
    $vmSubName = ($subscriptions | ? { $_.Id -in $resource.subscriptionId }).Name
    $protectedItem = Search-AzGraph -Query "recoveryservicesresources | where type == 'microsoft.recoveryservices/vaults/backupfabrics/protectioncontainers/protecteditems' and properties.virtualMachineId =~ '$($resource.id)'"
    if ($protectedItem) {
        $rsvName = $protectedItem.Id.Split('/')[8]
        $protectionState = $protectedItem.properties.protectionState
        $lastBackupStatus = $protectedItem.properties.lastBackupStatus
        $lastRecoveryPoint = $protectedItem.properties.lastRecoveryPoint
        $rsvResourceGroup = $protectedItem.Id.Split('/')[4]
        $rsvSubscriptionID = $protectedItem.Id.Split('/')[2]
        $rsvSubName = ($subscriptions | ? { $_.Id -in $rsvSubscriptionID }).Name
    }
    else {
        
        $rsvName = $null
        $protectionState = $null
        $lastBackupStatus = $null
        $lastRecoveryPoint = $null
        $rsvResourceGroup = $null
        $rsvSubscriptionID = $null
        $rsvSubName = $null
    }
    
    $outputObject = New-Object PSObject -Property @{
        "VMName"              = $resource.name
        "RSVName"             = $rsvName
        "ProtectionState"     = $protectionState
        "LastBackupStatus"    = $lastBackupStatus
        "LastRecoveryPoint"   = $lastRecoveryPoint
        "VMResourceGroup"     = $resource.resourceGroup
        "VMSubscriptionName"  = $vmSubName
        "VMSubscriptionID"    = $resource.subscriptionId
        "RSVResourceGroup"    = $rsvResourceGroup
        "RSVSubscriptionID"   = $rsvSubscriptionID
        "RSVSubscriptionName" = $rsvSubName
    }
    $output += $outputObject
}

$output | Select-Object `
VMName, `
RSVName, `
ProtectionState, `
LastBackupStatus, `
LastRecoveryPoint, `
VMResourceGroup, `
VMSubscriptionName, `
VMSubscriptionID, `
RSVResourceGroup, `
RSVSubscriptionID, `
RSVSubscriptionName `
| Export-Csv -NoTypeInformation $csvFile
