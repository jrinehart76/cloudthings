<#
.SYNOPSIS
    Deploys Azure SQL Database monitoring alerts for Azure Monitor.

.DESCRIPTION
    This script deploys comprehensive Azure Monitor alert rules for Azure SQL Databases,
    covering both performance and storage monitoring. The alerts include:
    
    Critical Alerts (Sev 3):
    - High DTU utilization (>90% for 15 minutes)
    - High CPU utilization (>90% for 15 minutes)
    - Critical storage space (<10% free)
    - Connection failures and deadlocks
    
    Warning Alerts (Sev 4):
    - Elevated DTU utilization (>80% for 15 minutes)
    - Elevated CPU utilization (>80% for 15 minutes)
    - Low storage space (<20% free)
    - Query performance degradation
    
    These alerts enable proactive monitoring of SQL databases to:
    - Prevent performance degradation and query timeouts
    - Identify capacity planning needs for DTU/vCore scaling
    - Detect storage exhaustion before database becomes read-only
    - Monitor connection health and deadlock issues
    - Meet SLA and compliance requirements
    
    IMPORTANT: Diagnostic settings must be configured on each SQL database to send
    metrics and logs to the Log Analytics workspace before these alerts will function.
    
    The script deploys ARM templates that create scheduled query alerts in Azure Monitor.

.PARAMETER agResourceGroup
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

.PARAMETER customerId
    The Log Analytics workspace ID (customer ID) where SQL database data is collected.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER version
    Alert rule version for tracking and management.
    Example: 'v1', 'v2'

.EXAMPLE
    .\ta-alerts-sql.ps1 -agResourceGroup 'rg-monitoring-prod' -subscriptionId '12345678-1234-1234-1234-123456789012' -workspaceLocation 'eastus' -workspaceResourceId '/subscriptions/12345/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod' -customerId '87654321-4321-4321-4321-210987654321' -version 'v1'

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
    - Diagnostic settings must be configured on each SQL database
    - ARM template files must be in the same directory:
      * alert.critical.sqldatabaseperf.json
      * alert.critical.sqldatabasedisk.json
      * alert.warning.sqldatabaseperf.json
      * alert.warning.sqldatabasedisk.json
    
    Alert Thresholds:
    - Critical DTU/CPU: >90% for 15 minutes
    - Warning DTU/CPU: >80% for 15 minutes
    - Critical Storage: <10% free space
    - Warning Storage: <20% free space
    
    Diagnostic Settings Required:
    - Each SQL database must have diagnostic settings enabled
    - Metrics and logs must be sent to the Log Analytics workspace
    - Without diagnostics, alerts will not trigger
    
    Impact: Provides comprehensive monitoring for Azure SQL Databases to prevent
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

    [Parameter(Mandatory=$true, HelpMessage="Azure subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true, HelpMessage="Full resource ID of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceResourceId,

    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace ID (customer ID)")]
    [ValidateNotNullOrEmpty()]
    [string]$customerId,

    [Parameter(Mandatory=$true, HelpMessage="Alert rule version")]
    [ValidateNotNullOrEmpty()]
    [string]$version
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Azure SQL Database Monitoring Alerts"
Write-Output "=========================================="
Write-Output "Resource Group: $agResourceGroup"
Write-Output "Workspace Location: $workspaceLocation"
Write-Output "Workspace ID: $customerId"
Write-Output "Alert Version: $version"
Write-Output ""
Write-Output "IMPORTANT: Diagnostic settings must be configured on each SQL database"
Write-Output ""

# Build action group resource IDs
# These action groups must already exist in the resource group
$actionGroupS3 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s3"  # Critical
$actionGroupS4 = "/subscriptions/$subscriptionId/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-warn-s4"  # Warning

# Deploy critical performance alerts (DTU >90%, CPU >90%)
Write-Output "Deploying SQL Database critical performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-critical-perf-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.sqldatabaseperf.json `
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
Write-Output "Deploying SQL Database critical storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-critical-disk-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.critical.sqldatabasedisk.json `
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

# Deploy warning performance alerts (DTU >80%, CPU >80%)
Write-Output "Deploying SQL Database warning performance alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-warning-perf-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.sqldatabaseperf.json `
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
Write-Output "Deploying SQL Database warning storage alerts..."
Try {
    New-AzResourceGroupDeployment `
        -Name "deploy-mssql-warning-disk-alert" `
        -ResourceGroupName $agResourceGroup `
        -TemplateFile ./alert.warning.sqldatabasedisk.json `
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
Write-Output "  - Critical Performance (DTU/CPU >90%)"
Write-Output "  - Critical Storage (<10% free)"
Write-Output "  - Warning Performance (DTU/CPU >80%)"
Write-Output "  - Warning Storage (<20% free)"
Write-Output ""
Write-Output "Next Steps:"
Write-Output "  - Verify diagnostic settings are enabled on all SQL databases"
Write-Output "  - Ensure metrics/logs are sent to workspace: $customerId"
Write-Output "=========================================="