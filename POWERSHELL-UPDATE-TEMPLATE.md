# PowerShell Script Update Template

## Quick Reference for Updating Scripts

Use this template when updating PowerShell scripts to meet enterprise standards.

## Standard Header Template

```powershell
<#
.SYNOPSIS
    [One-line description of what the script does]

.DESCRIPTION
    [Detailed description including:]
    - What the script does
    - Why it's important/business value
    - Key features and capabilities
    - Integration points
    
    The script:
    - [Key feature 1]
    - [Key feature 2]
    - [Key feature 3]

.PARAMETER ParameterName
    [Description of parameter, including valid values and defaults]

.PARAMETER AnotherParameter
    [Description of parameter]

.EXAMPLE
    .\ScriptName.ps1 -Parameter "value"
    
    [Explanation of what this example does]

.EXAMPLE
    .\ScriptName.ps1 -Parameter "value" -AnotherParameter "value"
    
    [Explanation of this more complex example]

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: [YYYY-MM-DD]
    
    Prerequisites:
    - [Required PowerShell modules]
    - [Required Azure permissions]
    - [Other dependencies]
    
    Impact: [Business impact statement - why this matters]

.VERSION
    X.Y.Z - [Version description]

.CHANGELOG
    X.Y.Z - [Changes in this version]
    X.Y.Z - [Previous version changes]
#>
```

## Standard Parameter Block

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true, HelpMessage="Description of required parameter")]
    [ValidateNotNullOrEmpty()]
    [string]$RequiredParameter,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Option1", "Option2", "Option3")]
    [string]$OptionalParameter = "Option1",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)
```

## Standard Script Structure

```powershell
# Initialize script variables
$ErrorActionPreference = "Stop"  # or "Continue" for automation runbooks
$successCount = 0
$failureCount = 0
$skippedCount = 0

try {
    # Header output
    Write-Output "=========================================="
    Write-Output "[Script Name]"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Parameter1: $Parameter1"
    Write-Output ""

    # Verify Azure connection (if needed)
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Main logic here
    Write-Output "Processing resources..."
    $resources = Get-AzResource
    Write-Output "Found $($resources.Count) resources"
    Write-Output ""

    # Process with progress tracking
    $count = 0
    foreach ($resource in $resources) {
        $count++
        
        # Show progress every N items
        if ($count % 50 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }

        try {
            # Process individual item
            # Update counters
            $successCount++
        } catch {
            Write-Warning "  Failed to process $($resource.Name): $_"
            $failureCount++
        }
    }

    # Summary output
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Summary"
    Write-Output "=========================================="
    Write-Output "Total Processed: $($resources.Count)"
    Write-Output "Successful: $successCount"
    Write-Output "Failed: $failureCount"
    Write-Output "Skipped: $skippedCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        TotalCount = $resources.Count
        SuccessCount = $successCount
        FailureCount = $failureCount
        SkippedCount = $skippedCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error: $_"
    throw
}
```

## Standard Usage Notes Section

Add this at the end of the script:

```powershell
<#
USAGE NOTES:

1. Prerequisites:
   - [List required modules]
   - [List required permissions]
   - [List other dependencies]

2. Common Use Cases:
   - [Use case 1]
   - [Use case 2]
   - [Use case 3]

3. Output Analysis:
   - [How to interpret results]
   - [What to look for]
   - [Common issues]

4. Integration:
   - [How this integrates with other tools]
   - [Scheduling recommendations]
   - [Automation considerations]

5. Performance:
   - [Expected execution time]
   - [Resource requirements]
   - [Optimization tips]

EXPECTED RESULTS:
- [What success looks like]
- [Key metrics to track]
- [Validation steps]

REAL-WORLD IMPACT:
[Describe the business value and real-world benefits]

Without this script:
- [Problem 1]
- [Problem 2]

With this script:
- [Benefit 1]
- [Benefit 2]

TARGET METRICS:
- [Metric 1 and target]
- [Metric 2 and target]

NEXT STEPS:
1. [Follow-up action 1]
2. [Follow-up action 2]
3. [Follow-up action 3]
#>
```

## Common Patterns

### Azure Automation Runbook Connection

```powershell
# Connect using Automation Account Managed Identity
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
    
    Write-Output "Connected to Azure via Automation Account"
} catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
```

### Resource Graph Query Pattern

```powershell
# Use Resource Graph for efficient querying
$query = @"
resources
| where type == 'microsoft.compute/virtualmachines'
| where location == '$Location'
| project name, id, resourceGroup, subscriptionId, location
"@

$resources = Search-AzGraph -Query $query -First 5000
```

### Dynamic Output Path Pattern

```powershell
# Use dynamic paths instead of hardcoded user paths
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = [Environment]::GetFolderPath("MyDocuments")
$outputFile = Join-Path $outputPath "report-$timestamp.csv"
```

### Progress Tracking Pattern

```powershell
$total = $resources.Count
$current = 0

foreach ($resource in $resources) {
    $current++
    
    # Show progress every 50 items or at key milestones
    if ($current % 50 -eq 0 -or $current -eq $total) {
        $percentComplete = [math]::Round(($current / $total) * 100, 1)
        Write-Output "  Progress: $current/$total ($percentComplete%)"
    }
    
    # Process resource
}
```

## Checklist for Each Script

- [ ] Added comprehensive .SYNOPSIS
- [ ] Added detailed .DESCRIPTION with business value
- [ ] Documented all parameters with .PARAMETER
- [ ] Added at least 2 .EXAMPLE sections
- [ ] Added .NOTES with author "Jason Rinehart aka Technical Anxiety"
- [ ] Added prerequisites and dependencies
- [ ] Added .VERSION and .CHANGELOG
- [ ] Replaced hardcoded paths with dynamic paths
- [ ] Replaced hardcoded credentials with parameters
- [ ] Added [CmdletBinding()] for advanced functions
- [ ] Added parameter validation
- [ ] Added try/catch error handling
- [ ] Added Azure connection verification
- [ ] Added progress tracking for long operations
- [ ] Added summary statistics output
- [ ] Added USAGE NOTES section at end
- [ ] Tested with Get-Help
- [ ] Tested execution (or WhatIf)
- [ ] Updated version number
- [ ] Documented changes in changelog

## Testing Commands

```powershell
# Test help documentation
Get-Help .\ScriptName.ps1 -Full

# Test parameter help
Get-Help .\ScriptName.ps1 -Parameter ParameterName

# Test examples
Get-Help .\ScriptName.ps1 -Examples

# Test with WhatIf (if supported)
.\ScriptName.ps1 -Parameter "value" -WhatIf

# Test actual execution
.\ScriptName.ps1 -Parameter "value"
```

## Common Improvements

### Before: Hardcoded Path

```powershell
$csvFile = "C:\Users\JasonRinehart\Documents\output.csv"
```

### After: Dynamic Path

```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = [Environment]::GetFolderPath("MyDocuments")
$csvFile = Join-Path $outputPath "output-$timestamp.csv"
```

### Before: No Error Handling

```powershell
$vm = Get-AzVM -Name $vmName
Stop-AzVM -Name $vmName -Force
```

### After: Proper Error Handling

```powershell
try {
    $vm = Get-AzVM -Name $vmName -ErrorAction Stop
    if ($vm) {
        Stop-AzVM -Name $vmName -Force -ErrorAction Stop
        Write-Output "Successfully stopped VM: $vmName"
    }
} catch {
    Write-Error "Failed to stop VM $vmName: $_"
    throw
}
```

### Before: No Progress Tracking

```powershell
foreach ($vm in $vms) {
    # Process VM
}
```

### After: With Progress Tracking

```powershell
$total = $vms.Count
$current = 0

foreach ($vm in $vms) {
    $current++
    Write-Output "Processing VM $current/$total: $($vm.Name)"
    # Process VM
}
```

## Version Numbering

- **Major (X.0.0)**: Breaking changes, complete rewrites
- **Minor (1.X.0)**: New features, significant enhancements
- **Patch (1.0.X)**: Bug fixes, documentation updates

For this update effort:

- Scripts with complete rewrites: Bump to 2.0.0
- Scripts with enhanced documentation only: Bump to 1.1.0
- Scripts with minor fixes: Bump to 1.0.1

## Time Estimates

- **Simple script** (< 50 lines): 15 minutes
- **Medium script** (50-150 lines): 30 minutes
- **Complex script** (> 150 lines): 45-60 minutes

## Priority Order

1. **Critical Production Scripts** (automation runbooks)
2. **Frequently Used Scripts** (monitoring, backup, diagnostics)
3. **Deployment Scripts** (infrastructure deployment)
4. **Utility Scripts** (one-off, on-demand)

---

**Remember:** The goal is consistency, maintainability, and enterprise-grade quality across all PowerShell scripts.
