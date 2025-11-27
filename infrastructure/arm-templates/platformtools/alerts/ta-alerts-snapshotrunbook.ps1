<#
.SYNOPSIS
    Deploys Azure Automation snapshot runbook failure monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for Azure Automation snapshot runbook failures.
    Monitors: Runbook execution failures, snapshot creation errors
    Essential for: Backup automation health, data protection verification

.PARAMETER resourceGroup
    Resource group

.PARAMETER subscriptionId
    Subscription ID

.PARAMETER workspaceLocation
    Workspace location

.PARAMETER workspaceName
    Workspace name

.PARAMETER fileshareName
    File share name being monitored

.PARAMETER customerId
    Workspace ID

.EXAMPLE
    .\ta-alerts-snapshotrunbook.ps1 -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceLocation 'eastus' -workspaceName 'laws-prod' -fileshareName 'fileshare-data' -customerId '12345'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Automation Account, deployed snapshot runbook, action group MSP-alert-exec-s3
    Impact: Critical for ensuring backup automation is functioning properly

.VERSION
    2.0.0
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Workspace name")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceName,

    [Parameter(Mandatory=$true, HelpMessage="File share name")]
    [ValidateNotNullOrEmpty()]
    [string]$fileshareName,
    
    [Parameter(Mandatory=$true, HelpMessage="Workspace ID")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId
)

Write-Output "=========================================="
Write-Output "Deploy Snapshot Runbook Failure Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "File Share: $fileshareName"
Write-Output ""

# Build workspace resource ID from components
$workspaceResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/$workspaceName"
$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"

Write-Output "Deploying snapshot runbook failure alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-automation-critical-alerts" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.failedsnapshot.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -fileshareName $fileshareName `
        -ErrorAction Stop
    Write-Output "✓ Snapshot runbook failure alert deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
