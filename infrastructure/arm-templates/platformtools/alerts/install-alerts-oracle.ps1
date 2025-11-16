<#
    .DESCRIPTION
        Deploys all oracle alerts

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups
        Oracle Custom Log

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
$actionGroupDev   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/CUST-A-x-ag-dev"              #critical action group resource ID

##Deploy all alerts
##Critical Alerts begin here
New-AzResourceGroupDeployment `
    -Name "deploy-oracle-ogg-nonprod-critical-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.oracleogg.nonprod.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-oracle-ogg-prod-critical-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.oracleogg.prod.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-oracle-oradb-nonprod-critical-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.oracleora.nonprod.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-oracle-oradb-prod-critical-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.oracleora.prod.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version
