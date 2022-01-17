<#
    .DESCRIPTION
        Deploys AKS POD Status Alerts

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
#$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s2"          #critical action group resource ID
#$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-alert-exec-s3"
#$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-alert-warn-s4"
$actionGroupDev   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-sre-app"

##Deploy Kubernetes alert platform 
New-AzResourceGroupDeployment `
    -Name "deploy-aks-podstatus-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.critical.akspod.targeted.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version

#Removing deployment of warning alert but leaving it here just in case
<#
New-AzResourceGroupDeployment `
    -Name "deploy-aks-podstatus-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.warning.akspod.targeted.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupDev `
    -customerId $customerId `
    -version $version
#>