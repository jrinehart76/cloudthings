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
    [string]$storage,

    [Parameter(Mandatory=$true)]
    [string]$version,
    
    [Parameter(Mandatory=$true)]
    [string]$severity,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$storageResourceGroup
)

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-storage-event-error-alert" `
    -ResourceGroupName $storageResourceGroup `
    -TemplateFile ./alert.critical.saresponsetype.json `
    -version $version `
    -severity $severity `
    -storage $storage `
    -threshold $threshold `
    -subscriptionId $subscriptionId `
    -storageResourceGroup $storageResourceGroup