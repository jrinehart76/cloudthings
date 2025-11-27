<#
.SYNOPSIS
    Remove all MSP alerts, action groups, and logic apps from resource group

.DESCRIPTION
    This script removes all MSP-prefixed monitoring infrastructure from a
    resource group. Used for:
    - Environment decommissioning
    - Upgrade preparation
    - Migration to new monitoring solution
    - Cleanup of test environments
    
    The script removes:
    - All MSP-prefixed scheduled query rules (alerts)
    - All MSP-prefixed action groups
    - All MSP-prefixed logic apps
    - Excludes Oracle-specific alerts (preserved)
    
    WARNING: This will disable all MSP monitoring and alerting.
    Ensure you have a backup plan before running.

.PARAMETER ResourceGroupName
    Name of the resource group containing MSP monitoring resources

.PARAMETER WhatIf
    If true, shows what would be removed without making changes

.PARAMETER IncludeOracle
    If true, also removes Oracle-specific alerts (default: false)

.EXAMPLE
    .\ta-remove-alerts-all.ps1 -ResourceGroupName "rg-monitoring" -WhatIf
    
    Shows what would be removed without making changes

.EXAMPLE
    .\ta-remove-alerts-all.ps1 -ResourceGroupName "rg-test-monitoring"
    
    Removes all MSP monitoring from test environment

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Resources module
    - Contributor role on resource group
    
    WARNING: This disables all MSP monitoring. Use with caution.
    Recommended for decommissioning or upgrade scenarios only.

.VERSION
    2.0.0 - Enhanced documentation and safety features
    1.0.0 - Initial release
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group containing MSP monitoring resources")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeOracle
)

$ErrorActionPreference = "Continue"
$alertsRemoved = 0
$actionsRemoved = 0
$logicAppsRemoved = 0
$errorCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Remove MSP Monitoring Infrastructure"
    Write-Output "=========================================="
    Write-Output "WARNING: This will disable MSP monitoring!"
    Write-Output "Resource Group: $ResourceGroupName"
    Write-Output "Start Time: $(Get-Date)"
    Write-Output ""

    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    # Verify resource group exists
    Write-Output "Verifying resource group..."
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Output "Resource Group: $($rg.ResourceGroupName)"
    Write-Output "Location: $($rg.Location)"
    Write-Output ""

    # Build alert filter
    $alertFilter = if ($IncludeOracle) {
        { $_.Name -like "MSP-*" }
    } else {
        { ($_.Name -like "MSP-*") -and ($_.Name -notlike "*oracle*") }
    }

    # Get MSP alerts
    Write-Output "Discovering MSP alerts..."
    $alerts = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType microsoft.insights/scheduledqueryrules | 
        Where-Object $alertFilter
    Write-Output "Found $($alerts.Count) alert(s)"

    # Get MSP action groups
    Write-Output "Discovering MSP action groups..."
    $actions = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType microsoft.insights/actiongroups | 
        Where-Object { $_.Name -like "MSP-*" }
    Write-Output "Found $($actions.Count) action group(s)"

    # Get MSP logic apps
    Write-Output "Discovering MSP logic apps..."
    $logicApps = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Logic/workflows | 
        Where-Object { $_.Name -like "MSP-*" }
    Write-Output "Found $($logicApps.Count) logic app(s)"
    Write-Output ""

    # Confirm if not WhatIf
    if (-not $WhatIf) {
        $totalItems = $alerts.Count + $actions.Count + $logicApps.Count
        Write-Warning "About to remove $totalItems MSP monitoring resources!"
        Write-Output "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
        Start-Sleep -Seconds 10
    }

    # Remove alerts
    if ($alerts.Count -gt 0) {
        Write-Output "Removing alerts..."
        foreach ($alert in $alerts) {
            if ($WhatIf) {
                Write-Output "  WOULD REMOVE: $($alert.Name)"
                $alertsRemoved++
            } else {
                try {
                    Write-Output "  Removing: $($alert.Name)"
                    Remove-AzResource -ResourceId $alert.ResourceId -Force -ErrorAction Stop | Out-Null
                    Write-Output "    Result: SUCCESS"
                    $alertsRemoved++
                } catch {
                    Write-Warning "    Result: FAILED - $_"
                    $errorCount++
                }
            }
        }
        Write-Output ""
    }

    # Remove action groups
    if ($actions.Count -gt 0) {
        Write-Output "Removing action groups..."
        foreach ($action in $actions) {
            if ($WhatIf) {
                Write-Output "  WOULD REMOVE: $($action.Name)"
                $actionsRemoved++
            } else {
                try {
                    Write-Output "  Removing: $($action.Name)"
                    Remove-AzResource -ResourceId $action.ResourceId -Force -ErrorAction Stop | Out-Null
                    Write-Output "    Result: SUCCESS"
                    $actionsRemoved++
                } catch {
                    Write-Warning "    Result: FAILED - $_"
                    $errorCount++
                }
            }
        }
        Write-Output ""
    }

    # Remove logic apps
    if ($logicApps.Count -gt 0) {
        Write-Output "Removing logic apps..."
        foreach ($logicApp in $logicApps) {
            if ($WhatIf) {
                Write-Output "  WOULD REMOVE: $($logicApp.Name)"
                $logicAppsRemoved++
            } else {
                try {
                    Write-Output "  Removing: $($logicApp.Name)"
                    Remove-AzResource -ResourceId $logicApp.ResourceId -Force -ErrorAction Stop | Out-Null
                    Write-Output "    Result: SUCCESS"
                    $logicAppsRemoved++
                } catch {
                    Write-Warning "    Result: FAILED - $_"
                    $errorCount++
                }
            }
        }
        Write-Output ""
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Removal Summary"
    Write-Output "=========================================="
    Write-Output "Alerts Removed: $alertsRemoved"
    Write-Output "Action Groups Removed: $actionsRemoved"
    Write-Output "Logic Apps Removed: $logicAppsRemoved"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        AlertsRemoved = $alertsRemoved
        ActionsRemoved = $actionsRemoved
        LogicAppsRemoved = $logicAppsRemoved
        ErrorCount = $errorCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error: $_"
    throw
}

<#
USAGE NOTES:

WARNING: This script removes all MSP monitoring infrastructure.

1. Use Cases:
   - Environment decommissioning
   - Upgrade to new monitoring version
   - Migration to different monitoring solution
   - Cleanup of test/dev environments

2. Safety Measures:
   - 10-second delay before removal
   - WhatIf support to preview
   - Excludes Oracle alerts by default
   - Detailed logging of all actions

3. Removal Order:
   - Alerts first (stop triggering)
   - Action groups second (notification channels)
   - Logic apps last (event handlers)

4. After Removal:
   - No monitoring or alerting active
   - Reinstall if needed
   - Verify no dependencies remain

NEXT STEPS:
1. If upgrading, deploy new monitoring
2. Verify no orphaned resources
3. Update documentation
4. Test new monitoring if applicable
#>