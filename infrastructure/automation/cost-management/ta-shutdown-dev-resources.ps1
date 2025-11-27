<#
.SYNOPSIS
    Automatically shutdown development and test resources after business hours

.DESCRIPTION
    This runbook shuts down VMs and other resources in development/test environments
    to reduce costs. Based on the real-world example from "From Base Camp to Summit"
    where one client reduced monthly spend from $40,000 to $8,000.
    
    The runbook:
    - Identifies resources tagged as dev/test
    - Checks current time against business hours
    - Shuts down resources outside business hours
    - Logs all actions for audit trail
    - Sends summary report

.PARAMETER ResourceGroupPattern
    Pattern to match resource groups (e.g., "rg-dev-*", "rg-test-*")

.PARAMETER EnvironmentTag
    Tag name used to identify environment (default: "Environment")

.PARAMETER EnvironmentValues
    Comma-separated list of environment values to target (default: "dev,test,sandbox")

.PARAMETER BusinessHoursStart
    Start of business hours in 24-hour format (default: 07)

.PARAMETER BusinessHoursEnd
    End of business hours in 24-hour format (default: 19)

.PARAMETER TimeZone
    Timezone for business hours (default: "Eastern Standard Time")

.PARAMETER WhatIf
    If true, only reports what would be done without making changes

.PARAMETER ExcludeTag
    Tag name to exclude resources from shutdown (e.g., "AlwaysOn")

.EXAMPLE
    .\shutdown-dev-resources.ps1 -ResourceGroupPattern "rg-dev-*" -WhatIf $true

.EXAMPLE
    .\shutdown-dev-resources.ps1 -EnvironmentValues "dev,test" -BusinessHoursEnd 18

.NOTES
    Author: Jason Rinehart
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Real-world impact: Reduces dev/test costs by 60-75% by shutting down
    resources during non-business hours (nights, weekends).
    
    Typical savings: $2,000-5,000 per month for medium-sized environments.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupPattern = "rg-dev-*,rg-test-*",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentTag = "Environment",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentValues = "dev,test,sandbox",
    
    [Parameter(Mandatory=$false)]
    [int]$BusinessHoursStart = 7,
    
    [Parameter(Mandatory=$false)]
    [int]$BusinessHoursEnd = 19,
    
    [Parameter(Mandatory=$false)]
    [string]$TimeZone = "Eastern Standard Time",
    
    [Parameter(Mandatory=$false)]
    [bool]$WhatIf = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ExcludeTag = "AlwaysOn"
)

# Initialize counters
$shutdownCount = 0
$skippedCount = 0
$errorCount = 0
$estimatedMonthlySavings = 0

try {
    Write-Output "=========================================="
    Write-Output "Dev/Test Resource Shutdown Runbook"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "WhatIf Mode: $WhatIf"
    Write-Output ""

    # Connect to Azure using Managed Identity
    Write-Output "Connecting to Azure..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected successfully"
    Write-Output ""

    # Get current time in specified timezone
    $currentTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), $TimeZone)
    $currentHour = $currentTime.Hour
    $currentDay = $currentTime.DayOfWeek
    
    Write-Output "Current Time: $currentTime"
    Write-Output "Current Hour: $currentHour"
    Write-Output "Current Day: $currentDay"
    Write-Output "Business Hours: $BusinessHoursStart - $BusinessHoursEnd"
    Write-Output ""

    # Check if we're outside business hours
    $isWeekend = $currentDay -eq "Saturday" -or $currentDay -eq "Sunday"
    $isAfterHours = $currentHour -lt $BusinessHoursStart -or $currentHour -ge $BusinessHoursEnd
    
    if (-not ($isWeekend -or $isAfterHours)) {
        Write-Output "Currently within business hours. No shutdown needed."
        Write-Output "Next shutdown window: Today at $BusinessHoursEnd`:00"
        exit 0
    }

    Write-Output "Outside business hours - proceeding with shutdown"
    Write-Output ""

    # Get all resource groups matching pattern
    $patterns = $ResourceGroupPattern -split ","
    $resourceGroups = @()
    
    foreach ($pattern in $patterns) {
        $pattern = $pattern.Trim()
        Write-Output "Searching for resource groups matching: $pattern"
        $matchingGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like $pattern }
        $resourceGroups += $matchingGroups
        Write-Output "Found $($matchingGroups.Count) matching resource groups"
    }
    
    Write-Output ""
    Write-Output "Total resource groups to process: $($resourceGroups.Count)"
    Write-Output ""

    # Process each resource group
    foreach ($rg in $resourceGroups) {
        Write-Output "Processing Resource Group: $($rg.ResourceGroupName)"
        Write-Output "----------------------------------------"
        
        # Get all VMs in the resource group
        $vms = Get-AzVM -ResourceGroupName $rg.ResourceGroupName
        
        foreach ($vm in $vms) {
            Write-Output "  VM: $($vm.Name)"
            
            # Check if VM has exclude tag
            if ($vm.Tags.ContainsKey($ExcludeTag)) {
                Write-Output "    Status: SKIPPED (has $ExcludeTag tag)"
                $skippedCount++
                continue
            }
            
            # Check environment tag
            $envTag = $vm.Tags[$EnvironmentTag]
            $targetEnvs = $EnvironmentValues -split ","
            
            if ($envTag -and $targetEnvs -contains $envTag.ToLower()) {
                # Get VM status
                $vmStatus = Get-AzVM -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Status
                $powerState = $vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }
                
                if ($powerState.Code -eq "PowerState/running") {
                    Write-Output "    Current State: Running"
                    Write-Output "    Environment: $envTag"
                    
                    # Calculate estimated savings (approximate)
                    $vmSize = $vm.HardwareProfile.VmSize
                    $estimatedHourlyCost = switch -Wildcard ($vmSize) {
                        "Standard_B*" { 0.05 }
                        "Standard_D*" { 0.15 }
                        "Standard_E*" { 0.25 }
                        "Standard_F*" { 0.20 }
                        default { 0.10 }
                    }
                    $monthlyHours = 730 # Average hours per month
                    $afterHoursPercent = 0.65 # Approximate 65% of time is after hours
                    $monthlySavings = $estimatedHourlyCost * $monthlyHours * $afterHoursPercent
                    $estimatedMonthlySavings += $monthlySavings
                    
                    if ($WhatIf) {
                        Write-Output "    Action: WOULD SHUTDOWN (WhatIf mode)"
                        Write-Output "    Estimated Monthly Savings: `$$([math]::Round($monthlySavings, 2))"
                    } else {
                        try {
                            Write-Output "    Action: SHUTTING DOWN"
                            Stop-AzVM -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Force | Out-Null
                            Write-Output "    Result: SUCCESS"
                            Write-Output "    Estimated Monthly Savings: `$$([math]::Round($monthlySavings, 2))"
                            $shutdownCount++
                        } catch {
                            Write-Error "    Result: FAILED - $_"
                            $errorCount++
                        }
                    }
                } else {
                    Write-Output "    Current State: $($powerState.DisplayStatus)"
                    Write-Output "    Action: SKIPPED (already stopped)"
                    $skippedCount++
                }
            } else {
                Write-Output "    Environment: $envTag (not in target list)"
                Write-Output "    Action: SKIPPED (wrong environment)"
                $skippedCount++
            }
            Write-Output ""
        }
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Shutdown Summary"
    Write-Output "=========================================="
    Write-Output "VMs Shutdown: $shutdownCount"
    Write-Output "VMs Skipped: $skippedCount"
    Write-Output "Errors: $errorCount"
    Write-Output "Estimated Monthly Savings: `$$([math]::Round($estimatedMonthlySavings, 2))"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object for monitoring
    $summary = @{
        ShutdownCount = $shutdownCount
        SkippedCount = $skippedCount
        ErrorCount = $errorCount
        EstimatedMonthlySavings = [math]::Round($estimatedMonthlySavings, 2)
        ExecutionTime = Get-Date
        WhatIfMode = $WhatIf
    }
    
    return $summary

} catch {
    Write-Error "Fatal error in runbook: $_"
    throw
}

<#
USAGE NOTES:

1. Schedule this runbook to run:
   - Every evening at 7 PM (business hours end)
   - Every morning at 7 AM (to catch weekend resources)
   - Adjust based on your business hours

2. Tag your resources appropriately:
   - Environment: dev, test, sandbox
   - AlwaysOn: true (for resources that should never shutdown)

3. Test with WhatIf first:
   - Run with -WhatIf $true to see what would happen
   - Review the output before enabling actual shutdown

4. Monitor execution:
   - Check job history in Automation Account
   - Set up alerts for failures
   - Review monthly savings reports

5. Customize for your environment:
   - Adjust business hours
   - Modify timezone
   - Add additional resource types (App Services, SQL, etc.)

EXPECTED RESULTS:
- 60-75% reduction in dev/test compute costs
- Typical savings: $2,000-5,000/month
- Zero impact on business hours operations
- Automated, consistent enforcement

REAL-WORLD EXAMPLE:
One energy sector client was spending $40,000/month on dev environments
running 24/7. After implementing this runbook, costs dropped to $8,000/month
- a savings of $32,000/month or $384,000/year.
#>
