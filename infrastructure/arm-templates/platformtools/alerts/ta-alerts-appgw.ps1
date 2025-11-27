<#
.SYNOPSIS
    Deploys Application Gateway backend health monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for Application Gateway backend
    health monitoring. The alerts monitor:
    
    - Unhealthy backend instance count (v1 and v2 SKUs)
    - Backend pool health degradation
    - Critical severity (Sev 3) for immediate response
    
    Application Gateway health monitoring is essential for:
    - Detecting backend server failures
    - Ensuring application availability
    - Identifying load balancing issues
    - Meeting SLA requirements
    
    The script deploys separate alerts for v1 and v2 Application Gateway SKUs.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID).

.PARAMETER resourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER subscriptionId
    The Azure subscription ID.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.EXAMPLE
    .\ta-alerts-appgw.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceResourceId '/subscriptions/87654321/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-exec-s3 must be pre-deployed
    - Application Gateway diagnostic settings must be configured
    
    Impact: Critical for ensuring Application Gateway backend health and
    application availability. Unhealthy backends can cause service disruptions.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Workspace ID")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation
)

Write-Output "=========================================="
Write-Output "Deploy Application Gateway Health Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"

Write-Output "Deploying Application Gateway v1 unhealthy backend alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-appgw-v1-unhealthly-health-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.appgwunhealthycount.v1.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ App Gateway v1 alert deployed"
}
Catch {
    Write-Error "Failed to deploy v1 alert: $_"
    throw
}

Write-Output "Deploying Application Gateway v2 unhealthy backend alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-appgw-v2-unhealthly-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.appgwunhealthycount.v2.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ App Gateway v2 alert deployed"
}
Catch {
    Write-Error "Failed to deploy v2 alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 2 alert rules for Application Gateway backend health"
Write-Output "=========================================="
