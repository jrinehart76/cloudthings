<#
.SYNOPSIS
    Deploys Severity 1 App Service Plan monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for critical App Service Plan monitoring with Sev 1 escalation.
    Uses critical MIM action group for highest priority alerting.
    Monitors: Critical CPU, memory, HTTP errors for mission-critical App Service Plans
    Essential for: Mission-critical application monitoring, executive escalation

.PARAMETER agResourceGroup
    Resource group

.PARAMETER subscriptionId
    Subscription ID

.PARAMETER workspaceLocation
    Workspace location

.PARAMETER workspaceResourceId
    Workspace resource ID

.PARAMETER customerId
    Workspace ID

.PARAMETER version
    Alert version

.PARAMETER planName
    Specific App Service Plan name to monitor

.EXAMPLE
    .\ta-alerts-appsvc-sev1.ps1 -agResourceGroup 'rg-monitoring' -subscriptionId '12345' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/.../workspaces/laws' -customerId '67890' -version 'v1' -planName 'asp-prod-critical'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: App Service diagnostics, action group MSP-alert-critmim-s1
    Impact: Highest priority alerting for mission-critical applications

.VERSION
    2.0.0
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
    [string]$version,

    [Parameter(Mandatory=$true, HelpMessage="App Service Plan name")]
    [ValidateNotNullOrEmpty()]
    [string]$planName
)

Write-Output "=========================================="
Write-Output "Deploy Severity 1 App Service Plan Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "App Service Plan: $planName"
Write-Output "Alert Version: $version"
Write-Output "Severity: 1 (Critical MIM)"
Write-Output ""

$actionCritMIMS1 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-critmim-s1"

Write-Output "Deploying Severity 1 App Service Plan alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-appsvc-critical-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.appsvcplan.custom.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -version $version `
        -actionGroupId $actionCritMIMS1 `
        -customerId $customerId `
        -planName $planName `
        -ErrorAction Stop
    Write-Output "✓ Severity 1 App Service Plan alert deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
