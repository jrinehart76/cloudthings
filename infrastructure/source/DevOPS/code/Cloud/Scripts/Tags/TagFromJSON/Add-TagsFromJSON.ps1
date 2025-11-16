$subName = "subscription-nonprod-001"
$jsonTagFile = ".\Scripts\Tags\TagFromJSON\Tags.json"
$updateChildResrouces = $false
$purgeOldTags = $false
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1"
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

Write-AzureResourceGroupTagsFromJSON -InputFile $jsonTagFile -UpdateChildResrouces:$updateChildResrouces -PurgeOldTags:$purgeOldTags  -Verbose:$verboseOutput