$subName = "subscription-poc-001"
$rgName = "rg-region1-POC-CEP-China"
$purgeOldTags = $false
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1"
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

Copy-AzureTagsFromResourceGroup -ResourceGroupName $rgName -PurgeOldTags:$purgeOldTags -Verbose:$verboseOutput
