<#
    .DESCRIPTION
        Deploys all standard alerts

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups

    .TODO
        Modify to only install alerts that are needed

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$threshold,

    [Parameter(Mandatory=$true)]
    [string]$version,
    
    [Parameter(Mandatory=$false)]
    [string]$severity = '2',

    [Parameter(Mandatory=$true)]
    [string]$subscriptionid,

    [Parameter(Mandatory=$true)]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$deployResourceGroup

 )

##Create resource id variables
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"              #critical action group resource ID

$storageList = Get-AzStorageAccount

foreach ($storage in $storageList) {
    New-AzResourceGroupDeployment `
        -Name "deploy-azure-fileshare-critical-alert" `
        -ResourceGroupName $deployResourceGroup `
        -TemplateFile ./alert.critical.azfilecapacity.json `
        -threshold $threshold `
        -location $storage.Location `
        -storage $storage.StorageAccountName `
        -version $version `
        -severity $severity `
        -actionGroup $actionGroupS3 `
        -subscriptionId $subscriptionid `
        -storageResourceGroup $storage.ResourceGroupName
}

##Deploy alerts
