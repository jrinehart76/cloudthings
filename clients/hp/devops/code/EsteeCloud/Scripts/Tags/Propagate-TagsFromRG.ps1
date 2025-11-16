$subName = "CUST-A-AM-POC"
$rgName = "RG-AM-EastUS-POC-CEP-China"
$purgeOldTags = $false
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1"
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

Copy-AzureTagsFromResourceGroup -ResourceGroupName $rgName -PurgeOldTags:$purgeOldTags -Verbose:$verboseOutput
