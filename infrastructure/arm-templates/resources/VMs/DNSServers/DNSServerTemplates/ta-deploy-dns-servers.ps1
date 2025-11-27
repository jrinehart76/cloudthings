$subName = "subscription-prod-001"
$rgName = "rg-region1-Prod-PaaS-DNSServers"
$region = "eastus"
$deploymentPrefix = "US-AZR-PUDNS"
$templateFile = ".\Templates\VM\Linux-BindServer-nCopy\template.PasswordAuth.json"
$parameterFile = ".\Parameters\subscription-prod-001\rg-region1-Prod-PaaS-DNSServers\parameters.json"
$updateRGTags = $true
$verboseOutput = $true

##################################
Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput
Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput #-Force -ImportContext -PathToContextFile <PathToContextJSON>

New-AzureTemplateDeployment `
    -ResourceGroupName $rgName `
    -Location $region `
    -DeploymentPrefix $deploymentPrefix `
    -TemplateFilePath $templateFile `
    -ParameterFilePath $parameterFile `
    -IncludeParameterTags:$updateRGTags `
    -Verbose:$verboseOutput