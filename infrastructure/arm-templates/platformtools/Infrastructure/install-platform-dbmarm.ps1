##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true)]
    [string]$logicAppName,

    [Parameter(Mandatory=$true)]
    [string]$integrationAccountName,

    [Parameter(Mandatory=$true)]
    [string]$deploymentConnectionName,

    [Parameter(Mandatory=$true)]
    [string]$cosmosDbConnectionName,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

New-AzResourceGroupDeployment `
    -Name "deploy-PLATFORM-dashboard-manager-armdeploy" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.deployment.json `
    -logicAppLocation $logicAppLocation `
    -logicAppName $logicAppName `
    -integrationAccountName $integrationAccountName `
    -deploymentConnectionName $deploymentConnectionName `
    -cosmosDbConnectionName $cosmosDbConnectionName