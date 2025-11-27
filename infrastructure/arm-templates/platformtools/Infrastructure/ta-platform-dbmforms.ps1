<#
.SYNOPSIS
    Deploys the Dashboard Manager forms input Logic App.

.DESCRIPTION
    This script deploys the Logic App that processes Microsoft Forms submissions for
    dashboard requests. The Logic App:
    - Receives form submissions from Microsoft Forms
    - Validates and processes user input
    - Triggers the Dashboard Manager deployment Logic App
    - Provides a user-friendly interface for dashboard provisioning
    
    This forms-based workflow enables:
    - Self-service dashboard creation
    - Standardized input collection
    - Automated validation and processing
    - Integration with the broader Dashboard Manager system
    
    The Logic App acts as the front-end interface for dashboard automation.

.PARAMETER logicAppLocation
    The Azure region where the Logic App will be deployed.
    Example: 'eastus', 'westus2'

.PARAMETER logicAppName
    The name of the deployment Logic App that this forms Logic App will trigger.
    This should be the name of the Logic App deployed by ta-platform-dbmarm.ps1.
    Example: 'la-dashboard-manager-prod'

.PARAMETER resourceGroup
    The resource group where the Logic App will be deployed.
    Example: 'rg-platform-prod'

.EXAMPLE
    .\ta-platform-dbmforms.ps1 -logicAppLocation 'eastus' -logicAppName 'la-dashboard-manager-prod' -resourceGroup 'rg-platform-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Microsoft Forms API connection must be pre-deployed
    - Dashboard Manager deployment Logic App must exist (deployed by ta-platform-dbmarm.ps1)
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.form.input.json
    
    Post-Deployment:
    - Configure the Microsoft Forms connection if not already authorized
    - Create the Microsoft Form that will trigger this Logic App
    - Test the end-to-end workflow
    
    Related Scripts:
    - ta-platform-dbmconnections.ps1: Deploys the required API connections
    - ta-platform-dbmarm.ps1: Deploys the Dashboard Manager deployment Logic App
    
    Impact: Provides a user-friendly interface for dashboard provisioning requests.

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

    [Parameter(Mandatory=$true, HelpMessage="Name of the deployment Logic App to trigger")]
    [ValidateNotNullOrEmpty()]
    [string]$logicAppName,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Dashboard Manager Forms Logic App"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Location: $logicAppLocation"
Write-Output "Deployment Logic App: $logicAppName"
Write-Output ""

Try {
    # Deploy the forms input Logic App
    # This Logic App processes Microsoft Forms submissions for dashboard requests
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-dashboard-manager" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/dashboard_manager/logic_apps/logicapp.MSP.dashboard.form.input.json `
        -logicAppLocation $logicAppLocation `
        -deploymentLogicApp $logicAppName `
        -ErrorAction Stop
    
    Write-Output "✓ Dashboard Manager forms Logic App deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Dashboard Manager forms Logic App: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="