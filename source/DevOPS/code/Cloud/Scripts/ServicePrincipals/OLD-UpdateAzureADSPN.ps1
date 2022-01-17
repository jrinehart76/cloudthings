$servicePrincipalAppId = "AppId"
$newservicePrincipalAppKey = "NewAppPassword"
$subName = "GCCS"
$verboseOutput = $false

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

Remove-AzureRmADSpCredential -ServicePrincipalName $servicePrincipalAppId -All -Force
$securePassword = ConvertTo-SecureString $newservicePrincipalAppKey -AsPlainText -Force
New-AzureRmADSpCredential -ServicePrincipalName $servicePrincipalAppId -Password $securePassword