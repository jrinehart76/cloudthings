$subscriptions = Get-AzSubscription
$shareList = @()
$saError = @()

<#
foreach ($store in $allStorage) {
    if (!($store.Context.FileEndPoint)) {
        Write-Output "No fileshare found on [$($store.StorageAccountName)]"                    
    }
    else {
        $findShare = Get-AzStorageShare -Context $store.Context
        foreach ($share in $findShare) {
            Write-Output "Fileshare found [$($share.Name)] in storage account [$($store.StorageAccountName)]"
        }
    }
}
#>
foreach ($sub in $subscriptions) {
    Set-AzContext -Subscription $sub.Name
    $allStorage = Get-AzStorageAccount
    Write-Output ""
    Write-Output "Storage accounts found in subscription [$($sub.Name)]"
    $allStorage.StorageAccountName
    Write-Output ""
    foreach ($sa in $allStorage) {
        try {
            $shares = Get-AzStorageShare -Context $sa.Context -ErrorAction Stop
        }
        catch {
            $errorMessage = $_.Exception.Message
            $failedAccount = $_.Exception.ItemName
            if ($errorMessage -match "403") {
                $saError += $sa
                Write-Output "Not authorized to view fileshares on storage [$($sa.StorageAccountName)]"
                Write-Output ""
                Continue
            }
            else {
                if ($shares.Name) {
                    foreach ($share in $shares) {
                        Write-Output "Fileshare found [$($share.Name)] in storage [$($sa.StorageAccountName)]"
                        $shareList += $share 
                    }
                    Write-Output ""
                }
                else {
                    Write-Output "Fileshare not found in storage [$($sa.StorageAccountName)]"
                    Write-Output ""
                }
            }        
        }
    }
}