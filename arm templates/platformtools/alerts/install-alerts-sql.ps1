<#
    .DESCRIPTION
        Deploys Microsoft SQL Alerts

    .PREREQUISITES
        Log Analytics Workspace
        Action Groups
        Diagnostics configured on each database
    
    .EXAMPLE
        ./install-sqlAllAlerts.ps1

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (

    [Parameter(Mandatory=$true)]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$customerId,

    [Parameter(Mandatory=$true)]
    [string]$version

 )

##Create resource id variables
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s2"              
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s3"             
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-warn-s4" 

##Deploy sql alerting
    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-critical-perf-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.sqldatabaseperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version

    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-critical-disk-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.sqldatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version

    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-warning-perf-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.sqldatabaseperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId

    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-warning-disk-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.sqldatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId