<#
    .DESCRIPTION
        Deploys Azure Backup Failure alert

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$customerId,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,
    
    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$version

 )

##Create resource id variables
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s3"

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-azure-backup-failure-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.azbackup.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $version