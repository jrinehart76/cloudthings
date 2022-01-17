$appName = "AppName"
$password = "AppPassword"
$subName = "GCCS"
$verboseOutput = $false

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

Add-Type -Assembly System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(16,3)
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$sp = New-AzureRMADServicePrincipal -DisplayName $appName -Password $securePassword
Write-Host "`n############################################################"
Write-Host "AppName = $($appName)"
Write-Host "servicePrincipalAppId: $($sp.ApplicationId)"
Write-Host "servicePrincipalAppKey: $($password)"
Write-Host "AKV Secret Name: $($appName)------$($sp.ApplicationId)"
Write-Host "############################################################`n"