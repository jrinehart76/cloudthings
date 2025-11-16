$subName = "CUST-A-AM-POC"

##################################
Import-Module AzureRM
Add-AzureRMAccount
#Import-AzureRmContext -Path <PathToContextJSON>

Write-Host "Selecting subscription: $($subName)"
Select-AzureRmSubscription -SubscriptionName $subName | Out-Null

#Upgrade to v2
Register-AzureRmProviderFeature -FeatureName "InstantBackupandRecovery" –ProviderNamespace Microsoft.RecoveryServices


#Verify upgrade status
Get-AzureRmProviderFeature -FeatureName "InstantBackupandRecovery" –ProviderNamespace Microsoft.RecoveryServices