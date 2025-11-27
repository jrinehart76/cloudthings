<#
.SYNOPSIS
    Deploys Azure Backup failure monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys Azure Monitor alert rules to detect Azure Backup job failures.
    The alert monitors backup operations and triggers on:
    
    - Backup job failures (any VM backup that fails)
    - Restore job failures
    - Configuration backup failures
    - Critical severity (Sev 3) for immediate response
    
    Azure Backup monitoring is essential for:
    - Ensuring business continuity and disaster recovery readiness
    - Meeting compliance requirements for data protection
    - Detecting backup configuration issues early
    - Preventing data loss from undetected backup failures
    
    The script deploys ARM templates that create scheduled query alerts in Azure Monitor.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID) where backup data is collected.

.PARAMETER resourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.PARAMETER version
    Alert rule version for tracking and management.

.EXAMPLE
    .\ta-alerts-azbackup.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/87654321/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-exec-s3 must be pre-deployed
    - Azure Backup must be configured with diagnostic settings
    - Backup data must be sent to Log Analytics workspace
    
    Impact: Critical for ensuring backup operations are successful. Failed backups
    that go undetected can result in data loss during disaster recovery scenarios.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace ID")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,
    
    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Alert version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

Write-Output "=========================================="
Write-Output "Deploy Azure Backup Failure Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"

Write-Output "Deploying Azure Backup failure alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-azure-backup-failure-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.azbackup.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ Azure Backup failure alert deployed"
}
Catch {
    Write-Error "Failed to deploy backup alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="