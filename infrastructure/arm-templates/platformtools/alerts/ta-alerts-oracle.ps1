<#
.SYNOPSIS
    Deploys Oracle database monitoring alerts (OGG and ORA errors).

.DESCRIPTION
    Deploys Azure Monitor alerts for Oracle GoldenGate (OGG) and Oracle database (ORA) error monitoring.
    Separate alerts for production and non-production environments.
    
    Monitors: OGG replication errors, ORA database errors, critical database events
    Essential for: Database health, replication monitoring, proactive issue detection

.PARAMETER customerId
    Log Analytics workspace ID

.PARAMETER resourceGroup
    Resource group for alerts

.PARAMETER subscriptionId
    Azure subscription ID

.PARAMETER workspaceLocation
    Workspace location

.PARAMETER workspaceResourceId
    Workspace resource ID

.PARAMETER version
    Alert version

.EXAMPLE
    .\ta-alerts-oracle.ps1 -customerId '12345' -resourceGroup 'rg-monitoring' -subscriptionId '67890' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/.../workspaces/laws' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Oracle custom logs in Log Analytics, customer-specific action group
    Impact: Critical for Oracle database and replication health monitoring

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
Write-Output "Deploy Oracle Database Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Alert Version: $version"
Write-Output ""

$actionGroupDev = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/customer-ag-dev"

Write-Output "Deploying Oracle GoldenGate non-prod alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-oracle-ogg-nonprod-critical-alerts" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.oracleogg.nonprod.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupDev `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ OGG non-prod alerts deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying Oracle GoldenGate prod alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-oracle-ogg-prod-critical-alerts" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.oracleogg.prod.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupDev `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ OGG prod alerts deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying Oracle database non-prod alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-oracle-oradb-nonprod-critical-alerts" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.oracleora.nonprod.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupDev `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ Oracle DB non-prod alerts deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output "Deploying Oracle database prod alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-oracle-oradb-prod-critical-alerts" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.oracleora.prod.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupDev `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop | Out-Null
    Write-Output "✓ Oracle DB prod alerts deployed"
} Catch { Write-Error "Failed: $_"; throw }

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 4 alert rules for Oracle monitoring"
Write-Output "=========================================="
