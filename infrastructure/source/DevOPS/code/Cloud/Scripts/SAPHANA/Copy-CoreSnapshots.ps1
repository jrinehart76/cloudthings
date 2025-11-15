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
    $SAPResourceGroupName = "RG-AM-EastUS-SAP-NonProd-Compute",
    [int]
    $SasTokenDuration = 36000
)
# Copy step for the snaps/vhds
Install-Module Az -Force
Select-AzureRMSubscription -SubscriptionName SAP
$sourceSnapshots = Get-AzureRmSnapshot -ResourceGroupName $SAPResourceGroupName | ? { $_.Name -like "*EWM*" -and $_.Name -notlike "*-os.*" }

foreach ($source in $sourceSnapshots) {
    Select-AzureRMSubscription -SubscriptionName SAP
    #Generate the SAS for the snapshot 
    Write-Output "Retrieving SAS token for blob $source.Name..."
    $sas = Grant-AzureRmSnapshotAccess -ResourceGroupName $SAPResourceGroupName -SnapshotName $source.Name  -DurationInSecond $SasTokenDuration -Access Read 
    #Create the context for the storage account which will be used to copy snapshot to the storage account 
    Select-AzureRmSubscription -SubscriptionName $SubscriptionName
    Write-Output "Getting storage account key..."
    $key = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName
    $destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $key.Value[0]  
    #Copy the snapshot to the storage account 
    $destinationVHDFileName = $source.Name.Replace("EWMGOLDEN","vhd")
    Write-Output "Starting async copy of blob $source.Name."
    Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer vhds -DestContext $destinationContext -DestBlob $destinationVHDFileName -Force
}

# Wait until all blobs are copied over.  This could take a bit of time.
$stillCopying = $true
while($stillCopying) {
    $copyStatus = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName | Get-AzureStorageBlob -Container vhds | Get-AzureStorageBlobCopyState
    $checkStatus = $copyStatus | ? { $_.Status -eq "Pending" }
    if($checkStatus.Count -eq 0){
        $stillCopying = $false
    } else {
        Write-Output "Still copying one or more blobs.  Retrying in one minute."
        Start-Sleep -Seconds 60
    }
}