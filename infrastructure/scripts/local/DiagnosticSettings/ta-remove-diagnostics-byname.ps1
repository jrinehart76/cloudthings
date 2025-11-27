<#
.SYNOPSIS
    Remove diagnostic settings by name from Azure resources

.DESCRIPTION
    This script removes diagnostic settings with a specific name from resources.
    Used for:
    - Cleanup of specific diagnostic configurations
    - Removing misconfigured diagnostic settings
    - Preparation for reconfiguration
    - Targeted removal vs. removing all diagnostics
    
    The script:
    - Discovers resources based on optional tag filter
    - Checks for diagnostic settings with specified name
    - Removes matching diagnostic settings
    - Uses parallel job execution for performance
    
    Real-world impact: Enables targeted cleanup of specific diagnostic
    configurations without affecting other diagnostic settings.

.PARAMETER diagName
    Name of the diagnostic setting to remove (e.g., "MSPDiagnosticsLog")

.PARAMETER tagName
    Optional tag name to filter resources (e.g., "Environment")

.PARAMETER tagValue
    Optional tag value to filter resources (e.g., "dev")

.PARAMETER Throttle
    Maximum number of parallel removal jobs (default: 5)

.EXAMPLE
    .\ta-remove-diagnostics-byname.ps1 -diagName "MSPDiagnosticsLog"
    
    Removes diagnostic setting named "MSPDiagnosticsLog" from all resources

.EXAMPLE
    .\ta-remove-diagnostics-byname.ps1 -diagName "OldDiagnostics" -tagName "Environment" -tagValue "dev"
    
    Removes diagnostic setting from dev environment resources only

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Monitor module
    - Monitoring Contributor role
    
    Impact: Removes specific diagnostic configurations.
    Use tag filtering to limit scope and prevent unintended removal.

.VERSION
    2.0.0 - Enhanced documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, progress tracking, error handling
    1.0.0 - Initial version with basic removal
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Name of diagnostic setting to remove")]
    [ValidateNotNullOrEmpty()]
    [string]$diagName,
    
    [Parameter(Mandatory=$false)]
    [string]$tagName,
    
    [Parameter(Mandatory=$false)]
    [string]$tagValue,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 20)]
    [int]$Throttle = 5
)

# Initialize script
$ErrorActionPreference = "Continue"
$jobs = @()
$removedCount = 0
$notFoundCount = 0
$errorCount = 0
$resources = @()

try {
    Write-Output "=========================================="
    Write-Output "Remove Diagnostic Settings by Name"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Diagnostic Setting Name: $diagName"
    Write-Output ""

    # Verify Azure connection
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    # Discover resources based on tag filter
    if ($tagValue -and $tagName) {
        Write-Output "Filter: Tag '$tagName' = '$tagValue'"
        $tagTable = @{$tagName = $tagValue}
        $resourceGroups = Get-AzResourceGroup -Tag $tagTable
        
        foreach ($resourceGroup in $resourceGroups) {
            $list = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
            if ($list) {
                $resources += $list
            }
        }
    } else {
        Write-Output "Filter: All resources in subscription"
        $resources = Get-AzResource
    }

    if ($resources.Count -eq 0) {
        Write-Warning "No resources found matching criteria"
        return
    }

    Write-Output "Found $($resources.Count) resource(s) to check"
    Write-Output ""

    # Define removal job script block
    $RemoveAzDiagnosticSettingsJob = {
        param ($diagName, $resourceId, $resourceName)
        
        try {
            Remove-AzDiagnosticSetting -Name $diagName `
                -ResourceId $resourceId `
                -WarningAction SilentlyContinue `
                -ErrorAction Stop
            
            return @{
                Success = $true
                ResourceName = $resourceName
                Message = "Removed successfully"
            }
        } catch {
            return @{
                Success = $false
                ResourceName = $resourceName
                Message = $_.Exception.Message
            }
        }
    }

    # Process each resource
    $count = 0
    foreach ($res in $resources) {
        $count++
        
        if ($count % 50 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }
        
        try {
            $diagSettings = Get-AzDiagnosticSetting -ResourceId $res.ResourceId `
                -ErrorAction Stop -WarningAction SilentlyContinue
            
            if ($diagSettings.Name -eq $diagName) {
                # Check job queue
                $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
                if ($runningJobs.Count -ge $Throttle) {
                    $runningJobs | Wait-Job -Any | Out-Null
                }
                
                # Start removal job
                $jobs += Start-Job -ScriptBlock $RemoveAzDiagnosticSettingsJob `
                    -ArgumentList $diagName, $res.ResourceId, $res.Name
            } else {
                $notFoundCount++
            }
        } catch {
            if (-not $_.Exception.ToString().Contains("BadRequest")) {
                $errorCount++
            }
        }
    }

    # Wait for jobs to complete
    if ($jobs.Count -gt 0) {
        Write-Output ""
        Write-Output "Waiting for removal jobs to complete..."
        $jobs | Wait-Job | Out-Null
        
        # Process results
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            if ($result.Success) {
                $removedCount++
            } else {
                Write-Warning "  [$($result.ResourceName)] FAILED - $($result.Message)"
                $errorCount++
            }
        }
        
        $jobs | Remove-Job
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Removal Summary"
    Write-Output "=========================================="
    Write-Output "Total Resources Checked: $($resources.Count)"
    Write-Output "Diagnostic Settings Removed: $removedCount"
    Write-Output "Not Found: $notFoundCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalResources = $resources.Count
        RemovedCount = $removedCount
        NotFoundCount = $notFoundCount
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

2. Use Cases:
   - Remove specific misconfigured diagnostic settings
   - Cleanup before reconfiguration
   - Remove old diagnostic configurations
   - Targeted removal vs. removing all

3. Safety:
   - Use tag filtering to limit scope
   - Test with small resource group first
   - Verify diagnostic setting name before running
   - Other diagnostic settings remain intact

4. Common Diagnostic Setting Names:
   - MSPDiagnosticsLog
   - diagnosticsHub
   - MySQLdiagnosticsLog
   - SQLdiagnosticsLog
   - service

NEXT STEPS:
1. Verify removal successful
2. Reconfigure diagnostics if needed
3. Verify monitoring still functional
#>