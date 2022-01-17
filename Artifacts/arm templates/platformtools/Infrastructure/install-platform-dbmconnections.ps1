##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

New-AzResourceGroupDeployment `
    -Name "deploy-10m-dashboard-manager-cosmosdb-conn" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/connections/api.connection.cosmosdb.json

New-AzResourceGroupDeployment `
    -Name "deploy-10m-dashboard-manager-msforms-conn" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/connections/api.connection.msforms.json

New-AzResourceGroupDeployment `
    -Name "deploy-10m-dashboard-manager-arm-conn" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/connections/api.connection.arm.json

New-AzResourceGroupDeployment `
    -Name "deploy-10m-dashboard-manager-integration" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/dashboard_manager/connections/integration.account.template.json