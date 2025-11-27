<#
.SYNOPSIS
    Deploys Windows VM monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys comprehensive Azure Monitor alert rules for Windows virtual
    machines, covering both performance and disk space monitoring. The alerts include:
    
    Critical Alerts (Sev 3):
    - High CPU utilization (>97% for 15 minutes)
    - High memory utilization (>97% for 15 minutes)
    - Critical disk space (<10% free space)
    
    Warning Alerts (Sev 4):
    - Elevated CPU utilization (>85% for 15 minutes)
    - Elevated memory utilization (>85% for 15 minutes)
    - Low disk space (<20% free space)
    
    These alerts enable proactive monitoring of Windows VMs to:
    - Prevent performance degradation and outages
    - Identify capacity planning needs
    - Detect resource exhaustion before service impact
    - Meet SLA and compliance requirements
    
    The script deploys ARM templates that create scheduled query alerts in Azure Monitor.

.PARAMETER agResourceGroup
    The resource group where alerts and action groups are deployed.
    Example: 'rg-monitoring-prod'

.PARAMETER workspaceResourceId
    The full resource ID of the Log Analytics workspace.
    Format: /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}

.PARAMETER workspaceLocation
    The Azure region where the Log Analytics workspace is located.
    Example: 'eastus', 'westus2'

.PARAMETER subscriptionId
    The Azure subscription ID containing the monitoring resources.
    Format: GUID

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID) where VM data is collected.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER version
    Alert rule version for tracking and management.
    Example: 'v1', 'v2'

.EXAMPLE
    .\ta-alerts-windows.ps1 -agResourceGroup 'rg-monitoring-prod' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -subscriptionId '12345678-1234-1234-1234-123456789012' -customerId '87654321-4321-4321-4321-210987654321' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed:
      * MSP-alert-exec-s2 (Sev 2 - not currently used)
      * MSP-alert-exec-s3 (Sev 3 - Critical)
      * MSP-alert-warn-s4 (Sev 4 - Warning)
    - User must have Contributor or Monitoring Contributor role
    - ARM template files must be in the same directory:
      * alert.critical.windowsperf.json
      * alert.critical.windowsdisk.json
      * alert.warning.windowsperf.json
      * alert.warning.windowsdisk.json
    
    Alert Thresholds:
    - Critical CPU/Memory: >97% for 15 minutes
    - Warning CPU/Memory: >85% for 15 minutes
    - Critical Disk: <10% free space
    - Warning Disk: <20% free space
    
    Impact: Provides comprehensive monitoring for Windows VMs to prevent outages,
    identify performance issues, and enable proactive capacity planning. Essential
    for maintaining service availability and meeting SLA commitments.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and error handling
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for alerts and action groups")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Full resource ID of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace ID (customer ID)")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Alert rule version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Windows VM Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output "Alert Version: $version"
Write-Output ""

# Build action group resource IDs
# These action groups must already exist in the resource group
$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"  # Critical
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"  # Warning

# Deploy critical performance alerts (CPU >97%, Memory >97%)
Write-Output "Deploying Windows critical performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-windows-critical-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.windowsperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ Critical performance alerts deployed"
}
Catch {
    Write-Error "Failed to deploy critical performance alerts: $_"
    throw
}

# Deploy critical disk space alerts (<10% free)
Write-Output "Deploying Windows critical disk space alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-windows-critical-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.windowsdisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ Critical disk space alerts deployed"
}
Catch {
    Write-Error "Failed to deploy critical disk alerts: $_"
    throw
}

# Deploy warning performance alerts (CPU >85%, Memory >85%)
Write-Output "Deploying Windows warning performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-windows-warning-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.windowsperf.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Warning performance alerts deployed"
}
Catch {
    Write-Error "Failed to deploy warning performance alerts: $_"
    throw
}

# Deploy warning disk space alerts (<20% free)
Write-Output "Deploying Windows warning disk space alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-windows-warning-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.windowsdisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Warning disk space alerts deployed"
}
Catch {
    Write-Error "Failed to deploy warning disk alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 4 alert rules:"
Write-Output "  - Critical Performance (CPU/Memory >97%)"
Write-Output "  - Critical Disk Space (<10% free)"
Write-Output "  - Warning Performance (CPU/Memory >85%)"
Write-Output "  - Warning Disk Space (<20% free)"
Write-Output "=========================================="