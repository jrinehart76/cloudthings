<#
.SYNOPSIS
    Remove all diagnostic settings from Azure resources

.DESCRIPTION
    This script removes diagnostic settings from all resources or resources
    matching specific tags. Use with caution - this will disable monitoring.
    Essential for:
    - Cleanup during decommissioning
    - Reconfiguration scenarios
    - Migration to new Log Analytics workspace
    - Testing and troubleshooting
    
    WARNING: This will disable monitoring and logging for affected resources.
    Ensure you have a backup plan before running.

.PARAMETER TagName
    Optional tag name to filter resources (e.g., "Environment")

.PARAMETER TagValue
    Optional tag value to filter resources (e.g., "dev")

.PARAMETER Throttle
    Maximum number of parallel removal jobs (default: 5)

.PARAMETER WhatIf
    If true, shows what would be removed without making changes

.EXAMPLE
    .\ta-remove-diagnostics-all.ps1 -TagName "Environment" -TagValue "dev" -WhatIf
    
    Shows what would be removed from dev environment

.EXAMPLE
    .\ta-remove-diagnostics-all.ps1 -TagName "Environment" -TagValue "test"
    
    Removes diagnostics from all test environment resources

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Monitor module
    - Monitoring Contributor role
    
    WARNING: This disables monitoring. Use with extreme caution.
    Recommended to use tag filtering to limit scope.

.VERSION
    2.0.0 - Enhanced documentation and safety features
    1.0.0 - Initial release
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$false)]
    [string]$TagName,
    
    [Parameter(Mandatory=$false)]
    [string]$TagValue,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 20)]
    [int]$Throttle = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"
$jobs = @()
$removedCount = 0
$skippedCount = 0
$errorCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Remove All Diagnostic Settings"
    Write-Output "=========================================="
    Write-Output "WARNING: This will disable monitoring!"
    Write-Output "Start Time: $(Get-Date)"
    Write-Output ""

    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    # Get resources based on tag filter
    if ($TagValue -and $TagName) {
        Write-Output "Filtering by tag: $TagName = $TagValue"
        $tagTable = @{$TagName = $TagValue}
        $resourceGroups = Get-AzResourceGroup -Tag $tagTable
        $resources = @()
        foreach ($rg in $resourceGroups) {
            $resources += Get-AzResource -ResourceGroupName $rg.ResourceGroupName
        }
    } else {
        Write-Output "Processing ALL resources in subscription"
        Write-Warning "No tag filter specified - this will affect ALL resources!"
        $resources = Get-AzResource
    }

    Write-Output "Found $($resources.Count) resources to process"
    Write-Output ""

    # Confirm if not WhatIf
    if (-not $WhatIf -and -not $TagValue) {
        Write-Warning "You are about to remove diagnostics from ALL resources!"
        Write-Output "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
        Start-Sleep -Seconds 10
    }

    $removeJob = {
        param($resourceId)
        try {
            Remove-AzDiagnosticSetting -ResourceId $resourceId -WarningAction SilentlyContinue -ErrorAction Stop
            return @{ Success = $true; ResourceId = $resourceId }
        } catch {
            return @{ Success = $false; ResourceId = $resourceId; Error = $_.Exception.Message }
        }
    }

    $count = 0
    foreach ($res in $resources) {
        $count++
        if ($count % 50 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }

        try {
            $diagSettings = Get-AzDiagnosticSetting -ResourceId $res.ResourceId -ErrorAction Stop -WarningAction SilentlyContinue
            
            if ($diagSettings.Name) {
                if ($WhatIf) {
                    Write-Output "  WOULD REMOVE: $($res.Name)"
                    $removedCount++
                } else {
                    $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
                    if ($runningJobs.Count -ge $Throttle) {
                        $runningJobs | Wait-Job -Any | Out-Null
                    }
                    
                    $jobs += Start-Job -ScriptBlock $removeJob -ArgumentList $res.ResourceId
                    $removedCount++
                }
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
        Write-Output "Waiting for removal jobs to complete..."
        $jobs | Wait-Job | Out-Null
        $jobs | Receive-Job | ForEach-Object {
            if (-not $_.Success) {
                Write-Warning "Failed: $($_.ResourceId)"
                $errorCount++
            }
        }
        $jobs | Remove-Job
    }

    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Summary"
    Write-Output "=========================================="
    Write-Output "Total Resources: $($resources.Count)"
    Write-Output "Diagnostics Removed: $removedCount"
    Write-Output "Skipped (No Diagnostics): $skippedCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

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

WARNING: This script disables monitoring. Use with extreme caution.

1. Recommended Usage:
   - Always use tag filtering to limit scope
   - Test with -WhatIf first
   - Use during maintenance windows
   - Document why diagnostics are being removed

2. Common Use Cases:
   - Decommissioning environments
   - Migrating to new Log Analytics workspace
   - Cleanup of test/dev resources
   - Troubleshooting diagnostic issues

3. Safety Measures:
   - 10-second delay when removing from all resources
   - WhatIf support to preview changes
   - Tag filtering to limit scope
   - Parallel execution with throttling

4. After Removal:
   - Resources will stop sending logs/metrics
   - Monitoring gaps will occur
   - Reconfigure diagnostics if needed
   - Verify monitoring coverage

NEXT STEPS:
1. If migrating, reconfigure with new workspace
2. Verify monitoring coverage after changes
3. Update documentation
4. Test alerting still works
#>