<#
.SYNOPSIS
    Deploys DDoS attack detection monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for DDoS attack detection.
    The alert monitors:
    
    - DDoS attack detection events
    - DDoS mitigation triggers
    - Network traffic anomalies
    - Critical severity (Sev 2) for immediate response
    
    DDoS monitoring is essential for:
    - Detecting distributed denial of service attacks
    - Enabling rapid incident response
    - Protecting application availability
    - Meeting security compliance requirements
    
    The script deploys ARM templates that create activity log alerts.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID).

.PARAMETER resourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER subscriptionId
    The Azure subscription ID.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.EXAMPLE
    .\ta-alerts-ddosattack.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/87654321/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-exec-s2 must be pre-deployed
    - Azure DDoS Protection Standard must be enabled
    
    Impact: Critical for detecting and responding to DDoS attacks that could
    disrupt application availability and business operations.

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

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,
    
    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId
)

Write-Output "=========================================="
Write-Output "Deploy DDoS Attack Detection Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output ""

$actionGroupS2 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"

Write-Output "Deploying DDoS attack detection alert..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-security-ddos-attack-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.ddosattack.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS2 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ DDoS attack detection alert deployed"
}
Catch {
    Write-Error "Failed to deploy DDoS alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="