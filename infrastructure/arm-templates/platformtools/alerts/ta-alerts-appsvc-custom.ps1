<#
.SYNOPSIS
    Deploys custom App Service Plan monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for specific App Service Plan monitoring with custom thresholds.
    Monitors: CPU, memory, HTTP errors for a specific App Service Plan
    Essential for: Application-specific performance monitoring, custom SLA tracking

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
    .\ta-alerts-appsvc-custom.ps1 -agResourceGroup 'rg-monitoring' -subscriptionId '12345' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/.../workspaces/laws' -customerId '67890' -version 'v1' -planName 'asp-prod-app1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: App Service diagnostics, action group MSP-alert-exec-s2
    Impact: Enables targeted monitoring for critical App Service Plans

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
Write-Output "Deploy Custom App Service Plan Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "App Service Plan: $planName"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS2 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"

Write-Output "Deploying custom App Service Plan alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-appsvc-critical-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.appsvcplan.custom.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -version $version `
        -actionGroupId $actionGroupS2 `
        -customerId $customerId `
        -planName $planName `
        -ErrorAction Stop
    Write-Output "✓ Custom App Service Plan alert deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
