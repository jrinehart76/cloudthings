##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$logicAppEnv,

    [Parameter(Mandatory=$true)]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true)]
    [string]$dynamicsCrmOnlineConnectionName,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

New-AzResourceGroupDeployment `
    -Name "deploy-10m-incident-managers-exceptions" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/alertmanager/alertmanager-incidents.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName

New-AzResourceGroupDeployment `
    -Name "deploy-10m-incident-managers-criticals" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/alertmanager/alertmanager-critical.json `
    -logicAppEnv $logicAppEnv `
    -logicAppLocation $logicAppLocation `
    -dynamicsCrmOnlineConnectionName $dynamicsCrmOnlineConnectionName