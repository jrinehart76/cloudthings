<#
.SYNOPSIS
    Audit diagnostic settings for Azure PaaS resources

.DESCRIPTION
    This script audits diagnostic settings configuration for key Azure PaaS
    resources across all subscriptions. Essential for:
    - Monitoring compliance verification
    - Log Analytics integration audit
    - Security and compliance reporting
    - Identifying unmonitored resources
    
    The script checks:
    - AKS clusters
    - Logic Apps
    - MySQL/SQL databases
    - Application Gateways
    - Recovery Services Vaults
    
    Real-world impact: Identifies monitoring gaps that could lead to
    blind spots in security, performance, and compliance.

.PARAMETER OutputPath
    Directory path where CSV report will be saved (default: user's Documents folder)

.PARAMETER SubscriptionFilter
    Optional subscription name pattern to filter (e.g., "prod*")

.PARAMETER ResourceTypes
    Comma-separated list of resource types to audit (default: all supported types)

.EXAMPLE
    .\ta-get-paas-extensions.ps1
    
    Audits all PaaS resources across all subscriptions

.EXAMPLE
    .\ta-get-paas-extensions.ps1 -OutputPath "C:\Reports" -SubscriptionFilter "prod*"
    
    Audits only production subscriptions

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Monitor module
    - Az.Resources module
    - Reader access to subscriptions
    
    Impact: Identifies monitoring gaps that create security and
    compliance blind spots.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added parameters, error handling, progress tracking, comprehensive documentation
    1.0.0 - Initial version with hardcoded paths
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionFilter = "*",
    
    [Parameter(Mandatory=$false)]
    [string[]]$ResourceTypes = @(
        'Microsoft.ContainerService/managedClusters',
        'Microsoft.Logic/workflows',
        'Microsoft.DBforMySQL/servers',
        'Microsoft.Sql/servers',
        'Microsoft.Sql/servers/databases',
        'Microsoft.Network/applicationGateways',
        'Microsoft.RecoveryServices/vaults'
    )
)

# Initialize script
$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = Join-Path $OutputPath "PaaSExtensionAudit-$timestamp.csv"
$results = @()
$monitoredCount = 0
$unmonitoredCount = 0

try {
    Write-Output "=========================================="
    Write-Output "PaaS Resource Diagnostic Settings Audit"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Output Path: $OutputPath"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Get subscriptions
    Write-Output "Discovering subscriptions..."
    $allSubscriptions = Get-AzSubscription
    $subscriptions = $allSubscriptions | Where-Object { $_.Name -like $SubscriptionFilter }
    
    if ($subscriptions.Count -eq 0) {
        throw "No subscriptions found matching filter: $SubscriptionFilter"
    }
    
    Write-Output "Found $($subscriptions.Count) subscriptions"
    Write-Output "Resource types to audit: $($ResourceTypes.Count)"
    Write-Output ""

    # Process each subscription
    $subCount = 0
    foreach ($sub in $subscriptions) {
        $subCount++
        Write-Output "[$subCount/$($subscriptions.Count)] Processing subscription: $($sub.Name)"
        Write-Output "----------------------------------------"
        
        try {
            Set-AzContext -Subscription $sub.Name -InformationAction SilentlyContinue | Out-Null
            
            # Get all resources
            Write-Output "  Discovering resources..."
            $allResources = Get-AzResource
            
            # Filter for monitored resource types
            $targetResources = $allResources | Where-Object { $ResourceTypes -contains $_.ResourceType }
            
            if ($targetResources.Count -eq 0) {
                Write-Output "  No target resources found"
                Write-Output ""
                continue
            }
            
            Write-Output "  Found $($targetResources.Count) target resource(s)"
            
            # Check diagnostic settings for each resource
            foreach ($resource in $targetResources) {
                Write-Output "  Checking: $($resource.Name) ($($resource.ResourceType))"
                
                try {
                    $diags = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId `
                        -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    
                    if ($diags -and $diags.WorkspaceId) {
                        # Resource has diagnostics configured
                        $monitoredCount++
                        
                        $results += [PSCustomObject]@{
                            SubscriptionName = $sub.Name
                            ResourceName = $resource.Name
                            ResourceType = $resource.ResourceType
                            ResourceGroup = $resource.ResourceGroupName
                            Location = $resource.Location
                            DiagnosticsName = $diags.Name
                            MetricsEnabled = if ($diags.Metrics) { $diags.Metrics[0].Enabled } else { $false }
                            LogsEnabled = if ($diags.Logs) { $diags.Logs[0].Enabled } else { $false }
                            WorkspaceId = $diags.WorkspaceId
                            Status = "Configured"
                        }
                    } else {
                        # Resource missing diagnostics
                        $unmonitoredCount++
                        
                        $results += [PSCustomObject]@{
                            SubscriptionName = $sub.Name
                            ResourceName = $resource.Name
                            ResourceType = $resource.ResourceType
                            ResourceGroup = $resource.ResourceGroupName
                            Location = $resource.Location
                            DiagnosticsName = "Missing"
                            MetricsEnabled = "Missing"
                            LogsEnabled = "Missing"
                            WorkspaceId = "Missing"
                            Status = "NOT CONFIGURED"
                        }
                    }
                } catch {
                    Write-Warning "    Error checking diagnostics: $_"
                }
            }
            
        } catch {
            Write-Warning "  Error processing subscription: $_"
        }
        
        Write-Output ""
    }

    # Export results
    Write-Output "Exporting results to CSV..."
    $results | Export-Csv -Path $csvFile -NoTypeInformation

    # Calculate compliance percentage
    $totalResources = $monitoredCount + $unmonitoredCount
    $compliancePercentage = if ($totalResources -gt 0) {
        [math]::Round(($monitoredCount / $totalResources) * 100, 2)
    } else {
        0
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Audit Summary"
    Write-Output "=========================================="
    Write-Output "Subscriptions Processed: $subCount"
    Write-Output "Total Resources Audited: $totalResources"
    Write-Output "Monitored (Configured): $monitoredCount"
    Write-Output "Unmonitored (Missing): $unmonitoredCount"
    Write-Output "Compliance Rate: $compliancePercentage%"
    Write-Output ""
    Write-Output "Output File: $csvFile"
    Write-Output ""
    
    # Show unmonitored resources
    $unmonitored = $results | Where-Object { $_.Status -eq "NOT CONFIGURED" }
    if ($unmonitored.Count -gt 0) {
        Write-Output "WARNING: UNMONITORED RESOURCES FOUND"
        Write-Output "=========================================="
        $unmonitored | Select-Object -First 10 ResourceName, ResourceType, ResourceGroup |
            Format-Table -AutoSize | Out-String | Write-Output
        
        if ($unmonitored.Count -gt 10) {
            Write-Output "... and $($unmonitored.Count - 10) more. See CSV for full list."
        }
    }
    
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalResources = $totalResources
        MonitoredCount = $monitoredCount
        UnmonitoredCount = $unmonitoredCount
        CompliancePercentage = $compliancePercentage
        OutputFile = $csvFile
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during PaaS extension audit: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Accounts, Az.Monitor, Az.Resources
   - Connect to Azure: Connect-AzAccount
   - Ensure Reader access to subscriptions

2. Monitored Resource Types:
   - AKS Clusters: Container insights and diagnostics
   - Logic Apps: Workflow execution logs
   - MySQL/SQL: Database performance and audit logs
   - Application Gateways: Access and performance logs
   - Recovery Services Vaults: Backup and restore logs

3. Compliance Requirements:
   - Security: All resources should send logs to SIEM
   - Performance: Metrics needed for capacity planning
   - Audit: Compliance requires centralized logging
   - Troubleshooting: Logs essential for issue resolution

4. Remediation:
   For unmonitored resources:
   - Use ta-configure-diagnostics-all.ps1 to enable
   - Or manually configure in Azure Portal
   - Ensure Log Analytics workspace exists
   - Verify permissions to configure diagnostics

5. Integration:
   - Schedule monthly for compliance reporting
   - Alert when compliance drops below threshold
   - Dashboard in Power BI or Azure Workbook
   - ServiceNow tickets for remediation

EXPECTED RESULTS:
- CSV report with all PaaS resources and diagnostic status
- Compliance percentage calculation
- List of unmonitored resources
- Foundation for monitoring compliance program

REAL-WORLD IMPACT:
Unmonitored resources create blind spots:

Without monitoring:
- Security incidents go undetected
- Performance issues discovered too late
- Compliance violations
- Extended troubleshooting time

With monitoring:
- Security incident detection
- Proactive performance management
- Compliance verification
- Faster troubleshooting

TARGET METRICS:
- 95%+ monitoring compliance
- 100% for production resources
- Zero critical resources unmonitored

NEXT STEPS:
1. Review unmonitored resources
2. Enable diagnostics for critical resources
3. Verify Log Analytics workspace configuration
4. Schedule regular compliance audits
5. Integrate with alerting and dashboards
#>
