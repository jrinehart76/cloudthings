<#
    .DESCRIPTION
        Runbook that takes a snapshot of the specified fileshare one per hour kept for 7 days
        Anything older than 7 days is removed

    .PREREQUISITES
        Az.Accounts
        Az.Storage

    .Example
        Runbook, no example available

    .TODO
        Adding more error catching to the results of the snapshot (9/17/2019)

    .NOTES
        AUTHOR: Jason Rinehart, Kyle Thompson [CloudPlatformProvider]

    .VERSION
        1.0 - Initial runbook
        1.1 - Updated

    .CHANGELOG  
        Inital runbook creation - JR
        Updated snapshot variable naming
        Updated remove snapshot command to resolve snapshot removal
    
#>

#Declare global variables
Param(
    [Parameter(Mandatory = $true)]
    [string]$storageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$storageAccountRG,

    [Parameter(Mandatory = $true)]
    [string]$fileShareName
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

#Create Snapshot
$storageAccount = Get-AzStorageAccount -ResourceGroupName $storageAccountRG -Name $storageAccountName
$share = Get-AzStorageShare -Context $storageAccount.Context -Name $fileShareName
Write-Output "Working with storage account [$($storageAccount.StorageAccountName)] and fileshare [$($share.Name)]"
$newSnapshot = $share.Snapshot()

#If the snapshot is true
if ($newSnapshot -and $newSnapshot.IsSnapshot -eq $true) {
    Write-Output "Snapshot successful [$($newSnapshot.Name)] [$($newSnapshot.SnapshotTime)]"
}

#If the snapshot failed
if ($newSnapshot.IsSnapshot -eq $false) {
    Write-Output "Snapshot failed [$($newSnapshot.Name)]"
    Return
}

#Get a list of all prior snapshots older than 7 days
$ssList = Get-AzStorageShare -Context $storageAccount.Context | Where-Object {$_.IsSnapshot -eq $true -and $_.SnapshotTime -lt ([datetime]::UtcNow.AddDays(-7))}

#If the list is not empty, delete all snapshots older than 7 days
if (!$ssList) {
    Write-Output "No older snapshots found for share [$($share.Name)]"
}
else {
    foreach ($ss in $ssList) {
        Write-Output "Old snapshot deleted [$($ss.SnapshotTime)] on share [$($ss.Name)]"
        Remove-AzStorageShare -Share $ss
    } 
}
