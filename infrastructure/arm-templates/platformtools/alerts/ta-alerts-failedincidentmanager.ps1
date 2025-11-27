<#
.SYNOPSIS
    Deploys Logic App incident manager failure monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for Logic App incident manager failures.
    Monitors: Logic App run failures, incident processing errors
    Essential for: Incident management automation health, ITSM integration

.PARAMETER resourceGroup
    Resource group

.PARAMETER subscriptionId
    Subscription ID

.PARAMETER workspaceResourceId
    Workspace resource ID

.PARAMETER workspaceLocation
    Workspace location

.EXAMPLE
    .\ta-alerts-failedincidentmanager.ps1 -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceResourceId '/subscriptions/.../workspaces/laws' -workspaceLocation 'eastus'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Logic App diagnostics, action group MSP-alert-crit-s1
    Impact: Critical for incident management automation and ITSM integration

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

    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation
)

Write-Output "=========================================="
Write-Output "Deploy Incident Manager Failure Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output ""

$actionGroupS1 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-crit-s1"

Write-Output "Deploying Logic App incident manager failure alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-failed-logicapp-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.incidentmanager.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS1 `
        -ErrorAction Stop
    Write-Output "✓ Incident manager failure alert deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
