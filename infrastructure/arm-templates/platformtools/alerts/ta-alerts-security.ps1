<#
.SYNOPSIS
    Deploys security event monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys Azure Monitor alert rules for security event monitoring.
    The alert monitors security-related events and triggers on:
    
    - Security Center recommendations
    - Security policy violations
    - Suspicious activity patterns
    - Informational severity (Sev 4) for awareness
    
    Security monitoring is essential for:
    - Detecting potential security threats early
    - Meeting compliance requirements
    - Maintaining security posture visibility
    - Enabling proactive security response
    
    The script deploys ARM templates that create scheduled query alerts in Azure Monitor.

.PARAMETER agResourceGroup
    The resource group where alerts and action groups are deployed.

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID).

.EXAMPLE
    .\ta-alerts-security.ps1 -agResourceGroup 'rg-monitoring-prod' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -subscriptionId '12345678-1234-1234-1234-123456789012' -customerId '87654321-4321-4321-4321-210987654321'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action group MSP-alert-info-s4 must be pre-deployed
    - Security Center data must be sent to Log Analytics
    
    Impact: Provides visibility into security events and recommendations for
    proactive security management and compliance.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Workspace location")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true, HelpMessage="Workspace ID")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId
)

Write-Output "=========================================="
Write-Output "Deploy Security Event Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output ""

$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-info-s4"

Write-Output "Deploying security informational alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-security-info-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.security.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Security informational alerts deployed"
}
Catch {
    Write-Error "Failed to deploy security alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="