<#
.SYNOPSIS
    Deploys agent heartbeat monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys Azure Monitor alert rules to detect when monitoring agents
    stop sending heartbeat signals, indicating potential agent failures or VM issues.
    
    The alert monitors:
    - Log Analytics agent (MMA/OMS) heartbeat signals
    - Missing heartbeats indicating agent or VM problems
    - Critical severity alerts for immediate response
    
    Agent heartbeat monitoring is essential for:
    - Detecting monitoring gaps that could hide other issues
    - Identifying VMs with failed or stopped agents
    - Ensuring continuous monitoring coverage
    - Meeting compliance requirements for monitoring
    
    The script deploys ARM templates that create scheduled query alerts in Azure Monitor.

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID) where agent data is collected.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER resourceGroup
    The resource group where alerts and action groups are deployed.
    Example: 'rg-monitoring-prod'

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.
    Format: GUID

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.
    Example: 'eastus', 'westus2'

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.
    Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}

.EXAMPLE
    .\ta-alerts-agent.ps1 -customerId '12345678-1234-1234-1234-123456789012' -resourceGroup 'rg-monitoring-prod' -subscriptionId '87654321-4321-4321-4321-210987654321' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/87654321-4321-4321-4321-210987654321/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/laws-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed (MSP-alert-exec-s3, MSP-alert-warn-s4)
    - User must have Contributor or Monitoring Contributor role
    - ARM template files must be in the same directory:
      * alert.critical.agent.json
    
    Alert Configuration:
    - Severity: Critical (Sev 3)
    - Action Group: MSP-alert-exec-s3
    - Query: Monitors Heartbeat table for missing agent signals
    
    Impact: Ensures monitoring agents are functioning properly. Missing heartbeats
    indicate monitoring gaps that could hide critical issues with VMs or applications.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace ID (customer ID)")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts and action groups")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,
    
    [Parameter(Mandatory=$true, HelpMessage="Full resource ID of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Agent Heartbeat Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output ""

# Build action group resource IDs
# These action groups must already exist in the resource group
$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"

Write-Output "Deploying agent heartbeat critical alert..."
Try {
    # Deploy the critical agent heartbeat alert
    # This alert triggers when agents stop sending heartbeat signals
    New-AzResourceGroupDeployment `
        -Name "deploy-agent-heartbeat-critical-alert" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./alert.critical.agent.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Agent heartbeat alert deployed successfully"
}
Catch {
    Write-Error "Failed to deploy agent heartbeat alert: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="

New-AzResourceGroupDeployment `
    -Name "deploy-agent-heartbeat-warning-alerts" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./alert.warning.agent.json `
    -workspaceLocation $workspaceLocation `
    -workspaceResourceId $workspaceResourceId `
    -actionGroupId $actionGroupS4 `
    -customerId $customerId
