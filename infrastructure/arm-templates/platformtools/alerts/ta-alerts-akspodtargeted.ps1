<#
.SYNOPSIS
    Deploys AKS pod status monitoring alerts (targeted namespaces).

.DESCRIPTION
    Deploys Azure Monitor alerts for AKS pod status monitoring in specific targeted namespaces.
    Uses custom action group for SRE/application teams.
    Monitors: Pod failures, CrashLoopBackOff, ImagePullBackOff, pending pods
    Essential for: Application-specific monitoring, team-based alerting

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

.PARAMETER version
    Alert version

.EXAMPLE
    .\ta-alerts-akspodtargeted.ps1 -customerId '12345' -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceResourceId '/subscriptions/.../workspaces/laws' -workspaceLocation 'eastus' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: AKS Container Insights, action group MSP-sre-app
    Impact: Enables targeted alerting for specific application teams

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
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Alert version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

Write-Output "=========================================="
Write-Output "Deploy AKS Pod Status Alerts (Targeted)"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupDev = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-sre-app"

Write-Output "Deploying AKS pod status critical alert (targeted)..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-podstatus-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.akspod.targeted.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupDev `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ Targeted critical alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Note: Warning alert deployment is disabled for targeted monitoring"
Write-Output "=========================================="
