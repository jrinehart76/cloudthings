<#
    .DESCRIPTION
        Deploys all linux alerts

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
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s2"              
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s3"             
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/10m-alert-warn-s4"              

New-AzResourceGroupDeployment `
    -Name "deploy-linux-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.linuxperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-linux-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.critical.linuxdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $version

New-AzResourceGroupDeployment `
    -Name "deploy-linux-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.warning.linuxperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-linux-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./alert.warning.linuxdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId