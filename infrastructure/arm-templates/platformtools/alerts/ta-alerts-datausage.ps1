<#
.SYNOPSIS
    Deploys Log Analytics workspace data usage monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for Log Analytics data ingestion
    monitoring. The alert monitors:
    
    - Daily data ingestion volume
    - Unexpected spikes in data usage
    - Approaching data cap limits
    - Warning severity (Sev 4) for cost awareness
    
    Data usage monitoring is essential for:
    - Controlling Log Analytics costs
    - Detecting misconfigured data collection
    - Identifying noisy data sources
    - Planning capacity and budgets
    
    The script deploys ARM templates that create scheduled query alerts.

.PARAMETER agResourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER subscriptionId
    The Azure subscription ID.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID).

.EXAMPLE
    .\ta-alerts-datausage.ps1 -agResourceGroup 'rg-monitoring-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -customerId '87654321-4321-4321-4321-210987654321'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-warn-s4 must be pre-deployed
    
    Impact: Helps control Log Analytics costs by alerting on unexpected data
    ingestion spikes and enabling proactive cost management.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace ID")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId
)

Write-Output "=========================================="
Write-Output "Deploy Log Analytics Data Usage Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output ""

$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

Write-Output "Deploying data usage warning alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-datausage-warning-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.datausage.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Data usage warning alert deployed"
}
Catch {
    Write-Error "Failed to deploy data usage alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="