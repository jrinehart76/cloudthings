<#
.SYNOPSIS
    Deploys high-severity security event monitoring alerts.

.DESCRIPTION
    Deploys Azure Monitor alerts for high-severity security events requiring immediate attention.
    
    Monitors: Critical security events, high-priority security recommendations, security policy violations
    Essential for: Security incident response, compliance, threat detection

.PARAMETER agResourceGroup
    Resource group for alerts

.PARAMETER workspaceResourceId
    Workspace resource ID

.PARAMETER workspaceLocation
    Workspace location

.PARAMETER subscriptionId
    Subscription ID

.PARAMETER customerId
    Workspace ID

.EXAMPLE
    .\ta-alerts-highsecurity.ps1 -agResourceGroup 'rg-monitoring' -workspaceResourceId '/subscriptions/.../workspaces/laws' -workspaceLocation 'eastus' -subscriptionId '12345' -customerId '67890'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Security Center data, action group MSP-alert-highsec-s2
    Impact: Critical for high-severity security event detection and response

.VERSION
    2.0.0
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group")]
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
Write-Output "Deploy High-Severity Security Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output ""

$actionGroupS2 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-highsec-s2"

Write-Output "Deploying high-severity security alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-high-security-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.security.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS2 `
        -customerId $customerId `
        -ErrorAction Stop
    Write-Output "✓ High-severity security alerts deployed"
}
Catch {
    Write-Error "Failed: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="