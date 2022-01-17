$subName = "GCCS"
$providerNamespace = "Microsoft.Network"
$resourceType = "virtualNetworks"
$verboseOutput = $false

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

((Get-AzureRmResourceProvider -ProviderNamespace $providerNamespace -Verbose:$verboseOutput).ResourceTypes | ?{$_.ResourceTypeName -eq $resourceType}).ApiVersions
