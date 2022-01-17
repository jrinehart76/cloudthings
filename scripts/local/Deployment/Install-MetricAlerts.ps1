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
    [string]$deploymentVersion,

    [Parameter(Mandatory=$true)]
    [string]$agResourceGroup
 )

##Create resource id variables
$actionGroupS1   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-action-crit-s1"
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-action-exec-s2"
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-action-exec-s3"              #critical action group resource ID
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-action-warn-s4"
#$actionGroupDev   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/10m-sre-app"

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-cpu-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.cpu.json `
    -alertName "10m-vm-warning-cpu-metric" `
    -alertSeverity "Warning" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 85 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-cpu-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.cpu.json `
    -alertName "10m-vm-critical-cpu-metric" `
    -alertSeverity "Critical" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 97 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId


New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-mem-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.memory.json `
    -alertName "10m-vm-warning-memory-metric" `
    -alertSeverity "Warning" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 85 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-mem-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.memory.json `
    -alertName "10m-vm-critical-memory-metric" `
    -alertSeverity "Critical" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 97 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-disk-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.disk.json `
    -alertName "10m-vm-warning-disk-metric" `
    -alertSeverity "Warning" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 20 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-vm-metric-disk-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.metric.disk.json `
    -alertName "10m-vm-critical-disk-metric" `
    -alertSeverity "Critical" `
    -alertFrequencyInMinutes 15 `
    -alertWindowInMinutes 60 `
    -alertThreshold 1 `
    -alertTriggerThreshold 10 `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion