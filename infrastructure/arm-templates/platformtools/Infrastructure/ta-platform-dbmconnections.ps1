<#
.SYNOPSIS
    Deploys API connections for the Dashboard Manager system.

.DESCRIPTION
    This script deploys all required API connections and integration accounts for the
    Dashboard Manager Logic Apps. It creates connections for:
    
    1. Cosmos DB Connection: Stores dashboard configurations and metadata
    2. Microsoft Forms Connection: Enables form-based dashboard requests
    3. ARM Connection: Allows Logic Apps to deploy ARM templates
    4. Integration Account: Provides B2B/EDI capabilities and schema management
    
    These connections enable the Dashboard Manager to:
    - Read dashboard configurations from Cosmos DB
    - Accept user input via Microsoft Forms
    - Deploy Azure resources using ARM templates
    - Process and transform data using integration schemas
    
    This script must be run before deploying the Dashboard Manager Logic Apps.

.PARAMETER resourceGroup
    The resource group where the API connections will be deployed.
    Example: 'rg-platform-prod'

.EXAMPLE
    .\ta-platform-dbmconnections.ps1 -resourceGroup 'rg-platform-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - User must have Contributor role on the resource group
    - Cosmos DB account must exist (for Cosmos DB connection)
    - ARM template files must exist in ./templates/dashboard_manager/connections/:
      * api.connection.cosmosdb.json
      * api.connection.msforms.json
      * api.connection.arm.json
      * integration.account.template.json
    
    Post-Deployment:
    - API connections may require authentication/authorization after deployment
    - Navigate to each connection in the Azure Portal to authorize
    - Integration Account can be configured with schemas and maps as needed
    
    Related Scripts:
    - ta-platform-dbmarm.ps1: Deploys the Dashboard Manager Logic App
    - ta-platform-dbmforms.ps1: Deploys the forms input Logic App
    
    Impact: Provides the foundational connectivity for the Dashboard Manager automation system.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for API connections")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Dashboard Manager API Connections"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output ""

Try {
    # Deploy Cosmos DB API connection
    # This connection enables Logic Apps to read/write dashboard configurations
    Write-Output "Deploying Cosmos DB connection..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager-cosmosdb-conn" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/connections/api.connection.cosmosdb.json `
        -ErrorAction Stop
    Write-Output "✓ Cosmos DB connection deployed"
    
    # Deploy Microsoft Forms API connection
    # This connection enables form-based dashboard requests
    Write-Output "Deploying Microsoft Forms connection..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager-msforms-conn" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/connections/api.connection.msforms.json `
        -ErrorAction Stop
    Write-Output "✓ Microsoft Forms connection deployed"
    
    # Deploy ARM API connection
    # This connection enables Logic Apps to deploy ARM templates
    Write-Output "Deploying ARM deployment connection..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager-arm-conn" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/connections/api.connection.arm.json `
        -ErrorAction Stop
    Write-Output "✓ ARM deployment connection deployed"
    
    # Deploy Integration Account
    # Provides B2B/EDI capabilities and schema management
    Write-Output "Deploying Integration Account..."
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager-integration" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/connections/integration.account.template.json `
        -ErrorAction Stop
    Write-Output "✓ Integration Account deployed"
    
    Write-Output ""
    Write-Output "✓ All Dashboard Manager connections deployed successfully"
    Write-Output ""
    Write-Output "IMPORTANT: API connections may require authorization"
    Write-Output "Navigate to each connection in Azure Portal to complete authentication"
}
Catch {
    Write-Error "Failed to deploy Dashboard Manager connections: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="