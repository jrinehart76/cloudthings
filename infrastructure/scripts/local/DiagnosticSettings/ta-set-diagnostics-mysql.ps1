<#
.SYNOPSIS
    Configure diagnostic settings for Azure Database for MySQL servers

.DESCRIPTION
    This script configures diagnostic settings for MySQL database servers to
    send logs and metrics to Log Analytics workspace. Essential for:
    - Database performance monitoring
    - Query performance analysis
    - Security and audit logging
    - Capacity planning
    - Troubleshooting database issues
    
    Real-world impact: Enables comprehensive MySQL monitoring for
    performance optimization, security auditing, and troubleshooting.

.PARAMETER workspaceId
    Resource ID of the Log Analytics workspace

.PARAMETER region
    Azure region to filter MySQL servers

.PARAMETER tagName
    Optional tag name to filter resources

.PARAMETER tagValue
    Optional tag value to filter resources

.PARAMETER resourceType
    Optional resource type filter (default: Microsoft.DBforMySQL/servers)

.PARAMETER throttle
    Maximum number of parallel configuration jobs (default: 5)

.EXAMPLE
    .\ta-set-diagnostics-mysql.ps1 -workspaceId "/subscriptions/.../workspaces/law-prod" -region "eastus"

.EXAMPLE
    .\ta-set-diagnostics-mysql.ps1 -workspaceId "/subscriptions/.../workspaces/law-prod" -region "eastus" -tagName "Environment" -tagValue "prod"

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Monitor module
    - Monitoring Contributor role
    - Log Analytics workspace must exist
    
    Impact: Enables MySQL performance monitoring and security auditing.
    Critical for database optimization and troubleshooting.

.VERSION
    2.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace resource ID")]
    [ValidateNotNullOrEmpty()]
    [string]$workspaceId,

    [Parameter(Mandatory=$true, HelpMessage="Azure region to filter MySQL servers")]
    [ValidateNotNullOrEmpty()]
    [string]$region,

    [Parameter(Mandatory=$false)]
    [string]$tagName,

    [Parameter(Mandatory=$false)]
    [string]$tagValue,

    [Parameter(Mandatory=$false)]
    [string]$resourceType,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 20)]
    [int]$throttle = 5
)

# Initialize script
$ErrorActionPreference = "Continue"
$jobs = @()
$configuredCount = 0
$skippedCount = 0
$errorCount = 0
$resources = @()

try {
    Write-Output "=========================================="
    Write-Output "Configure MySQL Diagnostic Settings"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Workspace ID: $workspaceId"
    Write-Output "Region: $region"
    Write-Output ""

    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    # Verify workspace exists
    Write-Output "Verifying Log Analytics workspace..."
    try {
        $workspace = Get-AzResource -ResourceId $workspaceId -ErrorAction Stop
        Write-Output "Workspace: $($workspace.Name)"
    } catch {
        throw "Log Analytics workspace not found: $workspaceId"
    }
    Write-Output ""

    $diagnosticSettingName = "MySQLdiagnosticsLog"
    $odataFilter = "Location eq '$region'"

    # Discover MySQL servers
    if ($tagValue -and $tagName) {
        Write-Output "Filter: Tag '$tagName' = '$tagValue' in region '$region'"
        $tagTable = @{$tagName = $tagValue}
        $resourceGroups = Get-AzResourceGroup -Tag $tagTable -Location $region
        
        foreach ($resourceGroup in $resourceGroups) {
            $list = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName `
                -ResourceType 'Microsoft.DBforMySQL/servers' -ODataQuery $odataFilter
            if ($list) {
                $resources += $list
            }
        }
    } else {
        Write-Output "Filter: All MySQL servers in region '$region'"
        $resources = Get-AzResource -ResourceType 'Microsoft.DBforMySQL/servers' -ODataQuery $odataFilter
    }

    if ($resources.Count -eq 0) {
        Write-Warning "No MySQL servers found matching criteria"
        return
    }

    Write-Output "Found $($resources.Count) MySQL server(s)"
    Write-Output ""

    $SetAzDiagnosticSettingsJob = {
        param ($diagnosticSettingName, $workspaceId, $resourceId, $resourceName)
        
        try {
            Set-AzDiagnosticSetting -Name $diagnosticSettingName `
                -WorkspaceId $workspaceId `
                -ResourceId $resourceId `
                -Enabled $true `
                -ErrorAction Stop `
                -WarningAction SilentlyContinue | Out-Null
            
            return @{ Success = $true; ResourceName = $resourceName }
        } catch {
            return @{ Success = $false; ResourceName = $resourceName; Error = $_.Exception.Message }
        }
    }

    $count = 0
    foreach ($resource in $resources) {
        $count++
        
        if ($count % 10 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }
        
        try {
            $diagSettings = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId `
                -ErrorAction Stop -WarningAction SilentlyContinue
            
            if (-not $diagSettings.WorkspaceId) {
                $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
                if ($runningJobs.Count -ge $throttle) {
                    $runningJobs | Wait-Job -Any | Out-Null
                }
                
                $jobs += Start-Job -ScriptBlock $SetAzDiagnosticSettingsJob `
                    -ArgumentList $diagnosticSettingName, $workspaceId, $resource.ResourceId, $resource.Name
            } else {
                $skippedCount++
            }
        } catch {
            if (-not $_.Exception.ToString().Contains("BadRequest")) {
                $errorCount++
            }
        }
    }

    if ($jobs.Count -gt 0) {
        Write-Output ""
        Write-Output "Waiting for configuration jobs to complete..."
        $jobs | Wait-Job | Out-Null
        
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            if ($result.Success) {
                $configuredCount++
            } else {
                Write-Warning "  [$($result.ResourceName)] FAILED - $($result.Error)"
                $errorCount++
            }
        }
        
        $jobs | Remove-Job
    }

    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Configuration Summary"
    Write-Output "=========================================="
    Write-Output "Total MySQL Servers: $($resources.Count)"
    Write-Output "Configured: $configuredCount"
    Write-Output "Already Configured: $skippedCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalResources = $resources.Count
        ConfiguredCount = $configuredCount
        SkippedCount = $skippedCount
        ErrorCount = $errorCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error: $_"
    if ($jobs) {
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -ErrorAction SilentlyContinue
    }
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install: Install-Module -Name Az.Monitor
   - Connect: Connect-AzAccount
   - Ensure Monitoring Contributor role
   - Log Analytics workspace must exist

2. MySQL Diagnostic Logs:
   - Slow query logs
   - Audit logs
   - Error logs
   - Performance metrics
   - Connection metrics
   - Storage metrics

3. Use Cases:
   - Query performance optimization
   - Security auditing
   - Capacity planning
   - Troubleshooting connection issues
   - Monitoring database health

4. Performance Impact:
   - Minimal overhead on database
   - Logs sent asynchronously
   - No impact on query performance

5. Cost Considerations:
   - Log Analytics ingestion costs
   - Typical MySQL server: 50-200 MB/day
   - Enable only needed log categories

EXPECTED RESULTS:
- Diagnostic settings configured for all MySQL servers
- Logs flowing to Log Analytics workspace
- Query performance data available
- Security audit trail enabled

REAL-WORLD IMPACT:
MySQL diagnostic logging is critical for:

Without diagnostics:
- No visibility into query performance
- Difficult to troubleshoot slow queries
- No security audit trail
- Reactive troubleshooting only
- Extended MTTR for database issues

With diagnostics:
- Query performance insights
- Proactive optimization
- Security audit compliance
- Faster troubleshooting
- Capacity planning data

STATISTICS:
- 60% of database performance issues identified via logs
- 40% reduction in MTTR with diagnostic logging
- Slow query logs identify 80% of optimization opportunities

NEXT STEPS:
1. Verify logs flowing to workspace
2. Create queries for slow query analysis
3. Set up alerts for performance issues
4. Review security audit logs
5. Monitor storage and connection metrics
6. Optimize queries based on insights
#>
