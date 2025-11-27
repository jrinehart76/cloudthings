$subName = "GCCS"
$rgName = "rg-region1-Prod-PaloAlto"
$deploymentPrefix = "VM-EastUS-SS-Palo01"
$templateFile = ".\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.PasswordAuth.json"
$parameterFile = ".\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.parameter.sample.json"

$region = "eastus"
$deploymentName = "$($deploymentPrefix)_$(Get-Date -Format yyyyMMdd_HHmm)"

##################################
Import-Module AzureRM
Add-AzureRMAccount

Write-Host "Selecting subscription: $($subName)"
Select-AzureRmSubscription -SubscriptionName $subName | Out-Null

$resourceGroup = Get-AzureRmResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Creating resource group $($rgName) in location $($region)"
    New-AzureRmResourceGroup -Name $rgName -Location $region
}
else {
    Write-Host "Using existing resource group $($rgName)"
}

Write-Host "Deploying template"
New-AzureRmResourceGroupDeployment `
    -ResourceGroupName $rgName `
    -Mode Incremental `
    -Name $deploymentName `
    -TemplateFile $templateFile `
    -TemplateParameterFile $parameterFile