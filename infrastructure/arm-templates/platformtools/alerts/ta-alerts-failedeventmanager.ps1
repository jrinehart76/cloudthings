<#
.SYNOPSIS
    Deploys Logic App event manager failure monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for Logic App event manager failures.
    Monitors: Logic App run failures, event processing errors
    Essential for: Event-driven automation health, integration monitoring

.PARAMETER customerId
    Workspace ID

.PARAMETER resourceGroup
    Resource group

.PARAMETER subscriptionId
    Subscription ID

.PARAMETER workspaceResourceId
    Workspace resource ID

.PARAMETER workspaceLocation
    Workspace location

.EXAMPLE
    .\ta-alerts-failedeventmanager.ps1 -customerId '12345' -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceResourceId '/subscriptions/.../workspaces/laws' -workspaceLocation 'eastus'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Logic App diagnostics, action group MSP-alert-crit-s1
    Impact: Critical for event-driven automation and integration health

.VERSION
    2.0.0
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
Write-Output "Deploy Event Manager Failure Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output ""

$actionGroupS1 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-crit-s1"

Write-Output "Deploying Logic App event manager failure alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-failed-logicapp-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.eventmanager.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS1 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ Event manager failure alert deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
