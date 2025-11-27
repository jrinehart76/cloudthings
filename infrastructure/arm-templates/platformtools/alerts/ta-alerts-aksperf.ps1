<#
.SYNOPSIS
    Deploys Azure Kubernetes Service (AKS) performance and node health monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for AKS cluster health and performance.
    The alerts monitor:
    
    Critical Alerts (Sev 3):
    - Node not ready status (node unavailable)
    - High CPU utilization (>90% for 15 minutes)
    - High memory utilization (>90% for 15 minutes)
    
    Warning Alerts (Sev 4):
    - Node not ready warning
    - Elevated CPU utilization (>80% for 15 minutes)
    - Elevated memory utilization (>80% for 15 minutes)
    
    AKS performance monitoring is essential for:
    - Detecting node failures and unavailability
    - Preventing pod scheduling issues
    - Identifying capacity planning needs
    - Ensuring cluster stability and availability
    
    The script deploys ARM templates that create scheduled query alerts.

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

.PARAMETER version
    Alert rule version for tracking and management.

.EXAMPLE
    .\ta-alerts-aksperf.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceResourceId '/subscriptions/87654321/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed
    - AKS Container Insights must be enabled
    
    Impact: Critical for AKS cluster stability. Node failures and resource exhaustion
    can cause pod evictions, scheduling failures, and application outages.

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
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Alert version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

Write-Output "=========================================="
Write-Output "Deploy AKS Performance & Node Health Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

Write-Output "Deploying AKS node not ready critical alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-nodenotready-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.aksnode.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Node not ready critical alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying AKS performance critical alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-perf-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.aksperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Performance critical alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying AKS node not ready warning alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-nodenotready-warning-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.warning.aksnode.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Node not ready warning alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying AKS performance warning alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-perf-warning-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.warning.aksperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Performance warning alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 4 alert rules for AKS monitoring"
Write-Output "==========================================" 