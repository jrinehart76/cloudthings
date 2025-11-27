<#
    .DESCRIPTION
        Deploys all windows alerts

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
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$customerId,

    [Parameter(Mandatory=$true)]
    [string]$version

 )

##Create resource id variables
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"              
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"             
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"   

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.postgredatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.postgredatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.warning.postgredatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.warning.postgredatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId