<#
.SYNOPSIS
    Deploys Azure Database for PostgreSQL monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys comprehensive Azure Monitor alert rules for Azure Database
    for PostgreSQL, covering both performance and storage monitoring. The alerts include:
    
    Critical Alerts (Sev 3):
    - High CPU utilization (>90% for 15 minutes)
    - High memory utilization (>90% for 15 minutes)
    - Critical storage space (<10% free)
    - High connection count (>90% of max connections)
    
    Warning Alerts (Sev 4):
    - Elevated CPU utilization (>80% for 15 minutes)
    - Elevated memory utilization (>80% for 15 minutes)
    - Low storage space (<20% free)
    - Elevated connection count (>80% of max connections)
    
    These alerts enable proactive monitoring of PostgreSQL databases to prevent
    outages, identify performance issues, and enable proactive capacity planning.

.PARAMETER agResourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID).

.PARAMETER version
    Alert rule version for tracking and management.

.EXAMPLE
    .\ta-alerts-postgresql.ps1 -agResourceGroup 'rg-monitoring-prod' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -subscriptionId '12345678-1234-1234-1234-123456789012' -customerId '87654321-4321-4321-4321-210987654321' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed
    - Diagnostic settings must be configured on each PostgreSQL database
    
    Impact: Provides comprehensive monitoring for Azure Database for PostgreSQL.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts and action groups")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Full resource ID of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace ID (customer ID)")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Alert rule version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

Write-Output "=========================================="
Write-Output "Deploy Azure Database for PostgreSQL Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

Write-Output "Deploying PostgreSQL critical performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-postgresqldatabase-critical-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.postgredatabaseperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    Write-Output "✓ Critical performance alerts deployed"
} Catch {
    Write-Error "Failed to deploy critical performance alerts: $_"
    throw
}

Write-Output "Deploying PostgreSQL critical storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-postgresqldatabase-critical-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.postgredatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    Write-Output "✓ Critical storage alerts deployed"
} Catch {
    Write-Error "Failed to deploy critical storage alerts: $_"
    throw
}

Write-Output "Deploying PostgreSQL warning performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-postgresqldatabase-warning-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.postgredatabaseperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Warning performance alerts deployed"
} Catch {
    Write-Error "Failed to deploy warning performance alerts: $_"
    throw
}

Write-Output "Deploying PostgreSQL warning storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-postgresqldatabase-warning-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.postgredatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Warning storage alerts deployed"
} Catch {
    Write-Error "Failed to deploy warning storage alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 4 alert rules for PostgreSQL databases"
Write-Output "=========================================="