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
$actionGroupS1   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-action-crit-s1"
$actionGroupS2   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-action-exec-s2"
$actionGroupS3   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-action-exec-s3"              #critical action group resource ID
$actionGroupS4   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-action-warn-s4"
#$actionGroupDev   = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-sre-app"

##Deploy alerts
New-AzResourceGroupDeployment `
    -Name "deploy-agent-heartbeat-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-agent-heartbeat-warning-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-aks-disk-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.aksdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-aks-disk-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.aksdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-aks-nodenotready-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.aksnode.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-perf-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.aksperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId
  
New-AzResourceGroupDeployment `
    -Name "deploy-aks-nodenotready-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.aksnode.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-perf-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.aksperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId 

New-AzResourceGroupDeployment `
    -Name "deploy-aks-podstatus-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.akspod.default.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-aks-podstatus-warning-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.akspod.default.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-appgw-v1-unhealthly-health-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.appgwunhealthycount.v1.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-appgw-v2-unhealthly-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.appgwunhealthycount.v2.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-datausage-warning-alert" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.datausage.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-security-ddos-attack-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-failed-logicapp-critical-alert" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.eventmanager.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS1 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-high-security-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.security.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS2 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-linux-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.linuxperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-linux-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.linuxdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-linux-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.linuxperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId `

New-AzResourceGroupDeployment `
    -Name "deploy-linux-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.linuxdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-mysqldatabase-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.mysqldatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-mysqldatabase-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.mysqldatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-mysqldatabase-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.mysqldatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-mysqldatabase-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.mysqldatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.postgredatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.postgredatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.postgredatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-postgresqldatabase-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.postgredatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-security-info-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.security.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-mssql-critical-perf-alert" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.sqldatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-mssql-critical-disk-alert" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.sqldatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-mssql-warning-perf-alert" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.sqldatabaseperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-mssql-warning-disk-alert" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.sqldatabasedisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-windows-critical-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.windowsperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-windows-critical-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.critical.windowsdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS3 `
    -customerId $customerId `
    -version $deploymentVersion

New-AzResourceGroupDeployment `
    -Name "deploy-windows-warning-perf-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.windowsperf.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

New-AzResourceGroupDeployment `
    -Name "deploy-windows-warning-disk-alerts" `
    -ResourceGroupName $agResourceGroup `
    -TemplateFile ./Platform/alerts/alert.warning.windowsdisk.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId

