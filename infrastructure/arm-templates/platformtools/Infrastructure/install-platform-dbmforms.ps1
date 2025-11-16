##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true)]
    [string]$logicAppName,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

New-AzResourceGroupDeployment `
    -Name "deploy-PLATFORM-dashboard-manager" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.form.input.json `
    -logicAppLocation $logicAppLocation `
    -deploymentLogicApp $logicAppName