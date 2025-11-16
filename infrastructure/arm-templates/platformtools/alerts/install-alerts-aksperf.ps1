<#
    .DESCRIPTION
        Deploys Kubernetes Node Not Ready Alerts

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
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$version
 )

##Create resource id variables
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"          #critical action group resource ID
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

##Deploy Kubernetes alert platform 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-nodenotready-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.aksnode.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-perf-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.aksperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId
  
New-AzResourceGroupDeployment `
    -Name "deploy-aks-nodenotready-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.warning.aksnode.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-perf-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.warning.aksperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId 