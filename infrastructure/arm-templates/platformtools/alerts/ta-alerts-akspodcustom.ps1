<#
.SYNOPSIS
    Deploys AKS pod status monitoring alerts (custom namespaces).

.DESCRIPTION
    Deploys Azure Monitor alerts for AKS pod status monitoring in custom namespaces.
    Monitors: Pod failures, CrashLoopBackOff, ImagePullBackOff, pending pods
    Essential for: Application health, pod scheduling issues, container failures

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
    .\ta-alerts-akspodcustom.ps1 -customerId '12345' -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceResourceId '/subscriptions/.../workspaces/laws' -workspaceLocation 'eastus' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: AKS Container Insights, action groups
    Impact: Critical for detecting pod failures and application issues

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
Write-Output "Deploy AKS Pod Status Alerts (Custom)"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"

Write-Output "Deploying AKS pod status critical alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-podstatus-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.akspod.custom.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ Critical alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying AKS pod status warning alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-aks-podstatus-warning-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.warning.akspod.custom.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ Warning alert deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
