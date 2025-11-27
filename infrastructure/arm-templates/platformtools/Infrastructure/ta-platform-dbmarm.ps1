<#
.SYNOPSIS
    Deploys the Dashboard Manager ARM deployment Logic App.

.DESCRIPTION
    This script deploys the Dashboard Manager Logic App that orchestrates ARM template
    deployments for Azure dashboards. The Logic App integrates with:
    - Azure Resource Manager for template deployments
    - Cosmos DB for dashboard configuration storage
    - Integration Account for B2B/EDI processing capabilities
    
    The Dashboard Manager automates:
    - Dashboard provisioning from templates
    - Configuration management via Cosmos DB
    - Deployment orchestration and tracking
    - Integration with forms for user input
    
    This is a core component of the platform's dashboard automation system.

.PARAMETER logicAppLocation
    The Azure region where the Logic App will be deployed.
    Example: 'eastus', 'westus2'

.PARAMETER logicAppName
    The name for the Dashboard Manager Logic App.
    Example: 'la-dashboard-manager-prod'

.PARAMETER integrationAccountName
    The name of the Integration Account to link with the Logic App.
    Integration Accounts provide B2B capabilities and schema management.
    Example: 'ia-platform-prod'

.PARAMETER deploymentConnectionName
    The name of the ARM deployment API connection.
    This connection enables the Logic App to deploy ARM templates.
    Example: 'arm-deployment-connection'

.PARAMETER cosmosDbConnectionName
    The name of the Cosmos DB API connection.
    This connection provides access to dashboard configuration data.
    Example: 'cosmosdb-dashboard-config'

.PARAMETER resourceGroup
    The resource group where the Logic App and connections will be deployed.
    Example: 'rg-platform-prod'

.EXAMPLE
    .\ta-platform-dbmarm.ps1 -logicAppLocation 'eastus' -logicAppName 'la-dashboard-manager-prod' -integrationAccountName 'ia-platform-prod' -deploymentConnectionName 'arm-deployment-connection' -cosmosDbConnectionName 'cosmosdb-dashboard-config' -resourceGroup 'rg-platform-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Integration Account must be pre-deployed
    - API connections (ARM and Cosmos DB) must be pre-deployed
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.deployment.json
    
    Related Scripts:
    - ta-platform-dbmconnections.ps1: Deploys the required API connections
    - ta-platform-dbmforms.ps1: Deploys the forms input Logic App
    
    Impact: Enables automated dashboard provisioning and management across the platform.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Azure region for the Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$logicAppLocation,

    [Parameter(Mandatory=$true, HelpMessage="Name for the Dashboard Manager Logic App")]
    [ValidateNotNullOrEmpty()]
    [string]$logicAppName,

    [Parameter(Mandatory=$true, HelpMessage="Name of the Integration Account")]
    [ValidateNotNullOrEmpty()]
    [string]$integrationAccountName,

    [Parameter(Mandatory=$true, HelpMessage="Name of the ARM deployment API connection")]
    [ValidateNotNullOrEmpty()]
    [string]$deploymentConnectionName,

    [Parameter(Mandatory=$true, HelpMessage="Name of the Cosmos DB API connection")]
    [ValidateNotNullOrEmpty()]
    [string]$cosmosDbConnectionName,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Dashboard Manager Logic App"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Logic App Name: $logicAppName"
Write-Output "Location: $logicAppLocation"
Write-Output "Integration Account: $integrationAccountName"
Write-Output ""

Try {
    # Deploy the Dashboard Manager Logic App
    # This Logic App orchestrates ARM template deployments for dashboards
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager-armdeploy" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.deployment.json `
        -logicAppLocation $logicAppLocation `
        -logicAppName $logicAppName `
        -integrationAccountName $integrationAccountName `
        -deploymentConnectionName $deploymentConnectionName `
        -cosmosDbConnectionName $cosmosDbConnectionName `
        -ErrorAction Stop
    
    Write-Output "✓ Dashboard Manager Logic App deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Dashboard Manager Logic App: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="