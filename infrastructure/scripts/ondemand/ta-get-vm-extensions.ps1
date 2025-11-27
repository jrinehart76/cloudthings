<#
.SYNOPSIS
    Audit VM extensions across all Azure subscriptions

.DESCRIPTION
    This script generates a comprehensive audit of all VM extensions across
    all accessible subscriptions. Essential for:
    - Extension compliance verification
    - Security and monitoring coverage audit
    - Version management and updates
    - Troubleshooting extension issues
    
    The script reports:
    - VMs with extensions installed
    - VMs without extensions (potential gaps)
    - Extension types, versions, and status
    - Auto-upgrade configuration
    
    Real-world impact: Identifies VMs without critical extensions
    (monitoring, security, backup) that create operational blind spots.

.PARAMETER OutputPath
    Directory path where CSV report will be saved (default: user's Documents folder)

.PARAMETER SubscriptionFilter
    Optional subscription name pattern to filter (e.g., "prod*")

.PARAMETER IncludeHealthy
    If true, includes VMs with all extensions healthy (default: false, shows only issues)

.EXAMPLE
    .\ta-get-vm-extensions.ps1
    
    Audits all VMs across all subscriptions

.EXAMPLE
    .\ta-get-vm-extensions.ps1 -OutputPath "C:\Reports" -SubscriptionFilter "prod*"
    
    Audits only production subscriptions

.EXAMPLE
    .\ta-get-vm-extensions.ps1 -IncludeHealthy
    
    Includes all VMs, even those with healthy extensions

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Compute module
    - Reader access to subscriptions
    
    Impact: Identifies VMs without critical extensions for monitoring,
    security, and backup - creating operational and security blind spots.

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
    [switch]$IncludeHealthy
)

# Initialize script
$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = Join-Path $OutputPath "VMExtensionAudit-$timestamp.csv"
$results = @()
$vmsWithExtensions = 0
$vmsWithoutExtensions = 0
$totalExtensions = 0

try {
    Write-Output "=========================================="
    Write-Output "VM Extension Audit"
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
    Write-Output ""

    # Process each subscription
    $subCount = 0
    foreach ($sub in $subscriptions) {
        $subCount++
        Write-Output "[$subCount/$($subscriptions.Count)] Processing subscription: $($sub.Name)"
        Write-Output "----------------------------------------"
        
        try {
            Set-AzContext -Subscription $sub.Name -InformationAction SilentlyContinue | Out-Null
            
            # Get all VMs
            Write-Output "  Discovering VMs..."
            $vms = Get-AzVM
            
            if ($vms.Count -eq 0) {
                Write-Output "  No VMs found"
                Write-Output ""
                continue
            }
            
            Write-Output "  Found $($vms.Count) VM(s)"
            
            # Check extensions for each VM
            $vmCount = 0
            foreach ($vm in $vms) {
                $vmCount++
                
                # Show progress every 25 VMs
                if ($vmCount % 25 -eq 0) {
                    Write-Output "    Processed $vmCount/$($vms.Count) VMs..."
                }
                
                try {
                    # Get VM extensions
                    $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
                    
                    if (-not $extensions -or $extensions.Count -eq 0) {
                        # VM has no extensions
                        $vmsWithoutExtensions++
                        
                        $results += [PSCustomObject]@{
                            SubscriptionName = $sub.Name
                            VMName = $vm.Name
                            ResourceGroup = $vm.ResourceGroupName
                            Location = $vm.Location
                            ExtensionType = "Not Installed"
                            ExtensionName = "Missing"
                            Version = "Missing"
                            ProvisioningState = "Missing"
                            AutoUpgradeMinorVersion = "Missing"
                            Status = "NO EXTENSIONS"
                        }
                    } else {
                        # VM has extensions
                        $vmsWithExtensions++
                        
                        foreach ($ext in $extensions) {
                            $totalExtensions++
                            
                            # Determine status
                            $status = if ($ext.ProvisioningState -eq "Succeeded") { "Healthy" } else { "ISSUE" }
                            
                            # Only include if IncludeHealthy or has issues
                            if ($IncludeHealthy -or $status -eq "ISSUE") {
                                $results += [PSCustomObject]@{
                                    SubscriptionName = $sub.Name
                                    VMName = $ext.VMName
                                    ResourceGroup = $ext.ResourceGroupName
                                    Location = $vm.Location
                                    ExtensionType = $ext.ExtensionType
                                    ExtensionName = $ext.Name
                                    Version = $ext.TypeHandlerVersion
                                    ProvisioningState = $ext.ProvisioningState
                                    AutoUpgradeMinorVersion = $ext.AutoUpgradeMinorVersion
                                    Status = $status
                                }
                            }
                        }
                    }
                } catch {
                    Write-Warning "    Error checking VM $($vm.Name): $_"
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

    # Calculate statistics
    $totalVMs = $vmsWithExtensions + $vmsWithoutExtensions
    $coveragePercentage = if ($totalVMs -gt 0) {
        [math]::Round(($vmsWithExtensions / $totalVMs) * 100, 2)
    } else {
        0
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Audit Summary"
    Write-Output "=========================================="
    Write-Output "Subscriptions Processed: $subCount"
    Write-Output "Total VMs: $totalVMs"
    Write-Output "VMs with Extensions: $vmsWithExtensions"
    Write-Output "VMs without Extensions: $vmsWithoutExtensions"
    Write-Output "Total Extensions Found: $totalExtensions"
    Write-Output "Extension Coverage: $coveragePercentage%"
    Write-Output ""
    Write-Output "Output File: $csvFile"
    Write-Output ""
    
    # Show VMs without extensions
    $noExtensions = $results | Where-Object { $_.Status -eq "NO EXTENSIONS" }
    if ($noExtensions.Count -gt 0) {
        Write-Output "WARNING: VMs WITHOUT EXTENSIONS"
        Write-Output "=========================================="
        $noExtensions | Select-Object -First 10 VMName, ResourceGroup, Location |
            Format-Table -AutoSize | Out-String | Write-Output
        
        if ($noExtensions.Count -gt 10) {
            Write-Output "... and $($noExtensions.Count - 10) more. See CSV for full list."
        }
    }
    
    # Show failed extensions
    $failedExtensions = $results | Where-Object { $_.Status -eq "ISSUE" }
    if ($failedExtensions.Count -gt 0) {
        Write-Output ""
        Write-Output "WARNING: EXTENSIONS WITH ISSUES"
        Write-Output "=========================================="
        $failedExtensions | Select-Object -First 10 VMName, ExtensionName, ProvisioningState |
            Format-Table -AutoSize | Out-String | Write-Output
        
        if ($failedExtensions.Count -gt 10) {
            Write-Output "... and $($failedExtensions.Count - 10) more. See CSV for full list."
        }
    }
    
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalVMs = $totalVMs
        VMsWithExtensions = $vmsWithExtensions
        VMsWithoutExtensions = $vmsWithoutExtensions
        TotalExtensions = $totalExtensions
        CoveragePercentage = $coveragePercentage
        OutputFile = $csvFile
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during VM extension audit: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Accounts, Az.Compute
   - Connect to Azure: Connect-AzAccount
   - Ensure Reader access to subscriptions

2. Critical Extensions:
   - Monitoring Agent: Required for Azure Monitor
   - Dependency Agent: Required for VM Insights
   - Diagnostics Extension: Required for boot diagnostics
   - Backup Extension: Required for Azure Backup
   - Security Extensions: Antimalware, vulnerability assessment

3. Extension Status:
   - Succeeded: Extension installed and healthy
   - Failed: Extension installation or update failed
   - Missing: No extensions installed (critical gap)

4. Remediation:
   For VMs without extensions:
   - Use ta-install-vm-monitoring.ps1 for monitoring
   - Use ta-install-vm-dependency.ps1 for dependency agent
   - Use ta-install-vm-diagnostics.ps1 for diagnostics
   - Use ta-enable-vm-backup.ps1 for backup

5. Integration:
   - Schedule monthly for compliance reporting
   - Alert when coverage drops below threshold
   - Dashboard in Power BI or Azure Workbook
   - ServiceNow tickets for remediation

EXPECTED RESULTS:
- CSV report with all VMs and their extensions
- Coverage percentage calculation
- List of VMs without extensions
- List of failed extensions
- Foundation for extension compliance program

REAL-WORLD IMPACT:
VMs without extensions create operational blind spots:

Without extensions:
- No monitoring or alerting
- No performance insights
- No backup protection
- No security scanning
- Extended troubleshooting time

With extensions:
- Centralized monitoring
- Performance insights
- Backup protection
- Security compliance
- Faster troubleshooting

STATISTICS:
- 30% of VMs typically lack monitoring extensions
- VMs without monitoring have 3x longer MTTR
- Extension failures cause 15% of VM issues
- Proper extension coverage reduces incidents by 40%

TARGET METRICS:
- 95%+ extension coverage
- 100% for production VMs
- Zero failed extensions
- All VMs have monitoring + backup

NEXT STEPS:
1. Review VMs without extensions
2. Install missing critical extensions
3. Investigate failed extensions
4. Verify auto-upgrade enabled
5. Schedule regular compliance audits
6. Integrate with monitoring dashboards
#>
