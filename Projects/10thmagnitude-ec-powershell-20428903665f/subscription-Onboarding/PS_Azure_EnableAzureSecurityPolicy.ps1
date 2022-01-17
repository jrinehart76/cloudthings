###########################################
# Azure Security Center
# default policy setup for subscriptions
###########################################


Install-Module -Name Azure-Security-Center
# Log in
Login-AzureRmAccount
#Get list of all accessible subscriptions by the user
$Subs = Get-AzureRmSubscription

#Show message in regards to what subscription to select, use regular expression to show only the subs that fit the naming XXX-YYYY
$SubsNames = $Subs.Name | Where-Object {$_ -match '^\S{3}' + "-" + '\S{4}$'}
Write-Host "Please select one of the subscriptions below to be used as the target for this resource group:" 
write-host ""

$SubsNames|format-table
Write-Host ""
$SubName = read-host "Copy and paste the name of the Subscription, for hub zone enter ITS-Shared"

#Select Subscription
$sub = Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $SubName}).Id

#####
# Azure Security Center
#####

#List default policy info
Get-ASCPolicy -PolicyName default | Format-List

#Build JSON of ASC Policy based on the Sub you are connected to (this just outputs the info, does not set it)
Build-ASCPolicy -PolicyName default

#Set Policy on Subscription

Set-ASCPolicy -PolicyName default -JSON `
(Build-ASCPolicy -PolicyName default -Patch On -Baseline On -AntiMalware On `
-DiskEncryption On -ACLS On -NSGS On -WAF Off -SQLAuditing On -SQLTDE On `
-NGFW Off -VulnerabilityAssessment Off -StorageEncryption On -JITNetworkAccess On `
-ApplicationWhitelisting On -DataCollection On `
-SecurityContactEmail "infosec-alerts@ecolab.com" -SecurityContactNotificationsOn true `
-SecurityContactSendToAdminOn false -PricingTier Standard -SecurityContactPhone "")
Build-ASCPolicy -PolicyName default