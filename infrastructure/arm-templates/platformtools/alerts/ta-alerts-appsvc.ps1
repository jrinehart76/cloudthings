<#
.SYNOPSIS
    Deploys Azure App Service monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for Azure App Service monitoring.
    The alerts monitor:
    
    - App Service Plan CPU utilization
    - App Service Plan memory utilization
    - HTTP server errors (5xx)
    - Response time degradation
    - Critical severity (Sev 3) for immediate response
    
    App Service monitoring is essential for:
    - Detecting performance degradation
    - Identifying capacity planning needs
    - Ensuring application availability
    - Meeting SLA requirements
    
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

.PARAMETER version
    Alert rule version for tracking and management.

.EXAMPLE
    .\ta-alerts-appsvc.ps1 -agResourceGroup 'rg-monitoring-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -customerId '87654321-4321-4321-4321-210987654321' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-exec-s3 must be pre-deployed
    - App Service diagnostic settings must be configured
    
    Impact: Ensures App Service performance and availability monitoring for
    proactive issue detection and capacity planning.

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
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Alert version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

Write-Output "=========================================="
Write-Output "Deploy Azure App Service Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"

Write-Output "Deploying App Service critical alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-appsvc-critical-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.appsvcplan.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -version $version `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ App Service critical alerts deployed"
}
Catch {
    Write-Error "Failed to deploy App Service alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="