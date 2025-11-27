<#
.SYNOPSIS
    Deploys Azure Kubernetes Service (AKS) disk space monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for AKS node disk space monitoring.
    The alerts monitor:
    
    Critical Alerts (Sev 3):
    - Node disk space <10% free
    - Persistent volume disk space critical
    
    Warning Alerts (Sev 4):
    - Node disk space <20% free
    - Persistent volume disk space low
    
    AKS disk monitoring is essential for:
    - Preventing pod evictions due to disk pressure
    - Avoiding node failures from full disks
    - Ensuring container image pull capability
    - Maintaining cluster stability
    
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
    .\ta-alerts-aksdisk.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceResourceId '/subscriptions/87654321/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed
    - AKS Container Insights must be enabled
    
    Impact: Critical for AKS cluster stability. Full disks can cause pod evictions,
    node failures, and cluster instability.

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
Write-Output "Deploy AKS Disk Space Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

Write-Output "Deploying AKS disk critical alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-disk-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.aksdisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ AKS disk critical alert deployed"
}
Catch {
    Write-Error "Failed to deploy critical alert: $_"
    throw
}

Write-Output "Deploying AKS disk warning alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-disk-warning-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.warning.aksdisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ AKS disk warning alert deployed"
}
Catch {
    Write-Error "Failed to deploy warning alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 2 alert rules for AKS disk space monitoring"
Write-Output "=========================================="