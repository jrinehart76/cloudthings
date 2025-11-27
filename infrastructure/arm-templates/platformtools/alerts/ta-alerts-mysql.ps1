<#
.SYNOPSIS
    Deploys Azure Database for MySQL monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys comprehensive Azure Monitor alert rules for Azure Database
    for MySQL, covering both performance and storage monitoring. The alerts include:
    
    Critical Alerts (Sev 3):
    - High CPU utilization (>90% for 15 minutes)
    - High memory utilization (>90% for 15 minutes)
    - Critical storage space (<10% free)
    - High connection count (>90% of max connections)
    
    Warning Alerts (Sev 4):
    - Elevated CPU utilization (>80% for 15 minutes)
    - Elevated memory utilization (>80% for 15 minutes)
    - Low storage space (<20% free)
    - Elevated connection count (>80% of max connections)
    
    These alerts enable proactive monitoring of MySQL databases to:
    - Prevent performance degradation and query timeouts
    - Identify capacity planning needs for compute/storage scaling
    - Detect storage exhaustion before database becomes read-only
    - Monitor connection pool exhaustion
    - Meet SLA and compliance requirements
    
    IMPORTANT: Diagnostic settings must be configured on each MySQL database to send
    metrics and logs to the Log Analytics workspace before these alerts will function.
    
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
    The Log Analytics workspace ID (customer ID) where MySQL database data is collected.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER version
    Alert rule version for tracking and management.
    Example: 'v1', 'v2'

.EXAMPLE
    .\ta-alerts-mysql.ps1 -agResourceGroup 'rg-monitoring-prod' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -workspaceLocation 'eastus' -subscriptionId '12345678-1234-1234-1234-123456789012' -customerId '87654321-4321-4321-4321-210987654321' -version 'v1'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Log Analytics workspace must exist
    - Action groups must be pre-deployed:
      * MSP-alert-exec-s3 (Sev 3 - Critical)
      * MSP-alert-warn-s4 (Sev 4 - Warning)
    - User must have Contributor or Monitoring Contributor role
    - Diagnostic settings must be configured on each MySQL database
    - ARM template files must be in the same directory:
      * alert.critical.mysqldatabaseperf.json
      * alert.critical.mysqldatabasedisk.json
      * alert.warning.mysqldatabaseperf.json
      * alert.warning.mysqldatabasedisk.json
    
    Alert Thresholds:
    - Critical CPU/Memory: >90% for 15 minutes
    - Warning CPU/Memory: >80% for 15 minutes
    - Critical Storage: <10% free space
    - Warning Storage: <20% free space
    
    Diagnostic Settings Required:
    - Each MySQL database must have diagnostic settings enabled
    - Metrics and logs must be sent to the Log Analytics workspace
    - Without diagnostics, alerts will not trigger
    
    Impact: Provides comprehensive monitoring for Azure Database for MySQL to prevent
    outages, identify performance issues, and enable proactive capacity planning.
    Essential for maintaining database availability and meeting SLA commitments.

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
Write-Output "Deploy Azure Database for MySQL Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output "Alert Version: $version"
Write-Output ""
Write-Output "IMPORTANT: Diagnostic settings must be configured on each MySQL database"
Write-Output ""

# Build action group resource IDs
# These action groups must already exist in the resource group
$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"  # Critical
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"  # Warning

# Deploy critical performance alerts (CPU >90%, Memory >90%)
Write-Output "Deploying MySQL critical performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mysqldatabase-critical-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.mysqldatabaseperf.json `
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

# Deploy critical storage alerts (<10% free)
Write-Output "Deploying MySQL critical storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mysqldatabase-critical-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.mysqldatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS3 `
        -customerId $customerId `
        -version $version `
        -ErrorAction Stop
    
    Write-Output "✓ Critical storage alerts deployed"
}
Catch {
    Write-Error "Failed to deploy critical storage alerts: $_"
    throw
}

# Deploy warning performance alerts (CPU >80%, Memory >80%)
Write-Output "Deploying MySQL warning performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mysqldatabase-warning-perf-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.mysqldatabaseperf.json `
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

# Deploy warning storage alerts (<20% free)
Write-Output "Deploying MySQL warning storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mysqldatabase-warning-disk-alerts" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.mysqldatabasedisk.json `
        -workspaceLocation $workspaceLocation `
        -workspaceResourceId $workspaceResourceId `
        -actionGroupId $actionGroupS4 `
        -customerId $customerId `
        -ErrorAction Stop
    
    Write-Output "✓ Warning storage alerts deployed"
}
Catch {
    Write-Error "Failed to deploy warning storage alerts: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Deployed 4 alert rules:"
Write-Output "  - Critical Performance (CPU/Memory >90%)"
Write-Output "  - Critical Storage (<10% free)"
Write-Output "  - Warning Performance (CPU/Memory >80%)"
Write-Output "  - Warning Storage (<20% free)"
Write-Output ""
Write-Output "Next Steps:"
Write-Output "  - Verify diagnostic settings are enabled on all MySQL databases"
Write-Output "  - Ensure metrics/logs are sent to workspace: $customerId"
Write-Output "=========================================="