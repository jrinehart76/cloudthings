<#
.SYNOPSIS
    Generate on-demand backup status report for all VMs across subscriptions

.DESCRIPTION
    This script generates a comprehensive backup status report for all VMs
    across all accessible subscriptions. Essential for:
    - Backup compliance verification
    - Disaster recovery readiness audit
    - Identifying unprotected VMs
    - Compliance and audit reporting
    
    The script:
    - Queries all accessible subscriptions
    - Checks backup status for each VM
    - Identifies VMs without backup protection
    - Exports results to CSV for analysis
    
    Real-world impact: Identifies VMs without backup protection that
    create data loss risk and compliance violations.

.PARAMETER OutputPath
    Directory path where CSV report will be saved (default: user's Documents folder)

.PARAMETER SubscriptionFilter
    Optional subscription name pattern to filter (e.g., "prod*")

.EXAMPLE
    .\ta-get-backup-status-ondemand.ps1
    
    Generates backup status report for all VMs across all subscriptions

.EXAMPLE
    .\ta-get-backup-status-ondemand.ps1 -OutputPath "C:\Reports" -SubscriptionFilter "prod*"
    
    Generates report for production subscriptions only

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Compute module
    - Az.RecoveryServices module
    - Reader access to subscriptions
    - Backup Reader role on Recovery Services Vaults
    
    Impact: Identifies VMs without backup protection.
    Unprotected VMs create data loss risk and compliance violations.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release by Erlin Tego

.CHANGELOG
    2.0.0 - Added parameters, error handling, progress tracking, comprehensive documentation
    1.0.0 - Initial version by Erlin Tego
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionFilter = "*"
)

# Initialize script
$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = Join-Path $OutputPath "BackupStatusAudit-$timestamp.csv"
$results = @()
$protectedCount = 0
$unprotectedCount = 0

try {
    Write-Output "=========================================="
    Write-Output "VM Backup Status Audit"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Output Path: $OutputPath"
    Write-Output ""

    # Verify Azure connection
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

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
            
            # Check backup status for each VM
            $vmCount = 0
            foreach ($vm in $vms) {
                $vmCount++
                
                if ($vmCount % 25 -eq 0) {
                    Write-Output "    Processed $vmCount/$($vms.Count) VMs..."
                }
                
                try {
                    # Get backup status
                    $status = Get-AzRecoveryServicesBackupStatus `
                        -Name $vm.Name `
                        -ResourceGroupName $vm.ResourceGroupName `
                        -Type AzureVM `
                        -ErrorAction Stop
                    
                    # Determine protection status
                    $isProtected = $status.BackedUp
                    if ($isProtected) {
                        $protectedCount++
                    } else {
                        $unprotectedCount++
                    }
                    
                    # Extract vault name from vault ID
                    $vaultName = if ($status.VaultId) {
                        ($status.VaultId -split '/')[-1]
                    } else {
                        "Not Protected"
                    }
                    
                    # Add to results
                    $results += [PSCustomObject]@{
                        SubscriptionName = $sub.Name
                        SubscriptionId = $sub.Id
                        VMName = $vm.Name
                        ResourceGroup = $vm.ResourceGroupName
                        Location = $vm.Location
                        BackupStatus = if ($isProtected) { "Protected" } else { "NOT PROTECTED" }
                        VaultName = $vaultName
                        VaultId = $status.VaultId
                    }
                    
                } catch {
                    Write-Warning "    Error checking backup status for $($vm.Name): $_"
                    
                    # Add error entry
                    $results += [PSCustomObject]@{
                        SubscriptionName = $sub.Name
                        SubscriptionId = $sub.Id
                        VMName = $vm.Name
                        ResourceGroup = $vm.ResourceGroupName
                        Location = $vm.Location
                        BackupStatus = "ERROR"
                        VaultName = "Error checking status"
                        VaultId = $null
                    }
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
    $totalVMs = $protectedCount + $unprotectedCount
    $compliancePercentage = if ($totalVMs -gt 0) {
        [math]::Round(($protectedCount / $totalVMs) * 100, 2)
    } else {
        0
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Backup Status Summary"
    Write-Output "=========================================="
    Write-Output "Subscriptions Processed: $subCount"
    Write-Output "Total VMs: $totalVMs"
    Write-Output "Protected: $protectedCount"
    Write-Output "Unprotected: $unprotectedCount"
    Write-Output "Compliance Rate: $compliancePercentage%"
    Write-Output ""
    Write-Output "Output File: $csvFile"
    Write-Output ""
    
    # Show unprotected VMs
    $unprotected = $results | Where-Object { $_.BackupStatus -eq "NOT PROTECTED" }
    if ($unprotected.Count -gt 0) {
        Write-Output "WARNING: UNPROTECTED VMs FOUND"
        Write-Output "=========================================="
        $unprotected | Select-Object -First 10 VMName, ResourceGroup, Location |
            Format-Table -AutoSize | Out-String | Write-Output
        
        if ($unprotected.Count -gt 10) {
            Write-Output "... and $($unprotected.Count - 10) more. See CSV for full list."
        }
    }
    
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalVMs = $totalVMs
        ProtectedCount = $protectedCount
        UnprotectedCount = $unprotectedCount
        CompliancePercentage = $compliancePercentage
        OutputFile = $csvFile
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during backup status audit: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install: Install-Module -Name Az.Compute, Az.RecoveryServices
   - Connect: Connect-AzAccount
   - Ensure Reader access to subscriptions
   - Ensure Backup Reader role on vaults

2. Backup Compliance:
   - Production VMs: 100% should be protected
   - Development VMs: 80%+ recommended
   - Test VMs: Optional based on data criticality
   - Critical VMs: Must have backup

3. Remediation:
   For unprotected VMs:
   - Use ta-enable-vm-backup.ps1 to enable
   - Ensure Recovery Services Vault exists
   - Verify VM in same region as vault
   - Check backup policy requirements

4. Integration:
   - Schedule monthly for compliance reporting
   - Alert when compliance drops below threshold
   - Dashboard in Power BI or Azure Workbook
   - ServiceNow tickets for remediation

EXPECTED RESULTS:
- CSV report with all VMs and backup status
- Compliance percentage calculation
- List of unprotected VMs
- Foundation for backup compliance program

REAL-WORLD IMPACT:
Unprotected VMs create critical data loss risk:

Without backup:
- Data loss from VM failures
- No recovery from ransomware
- Compliance violations
- Extended downtime
- Business impact

With backup:
- Point-in-time recovery
- Ransomware protection
- Compliance verification
- Reduced RTO/RPO
- Business continuity

TARGET METRICS:
- 95%+ backup compliance
- 100% for production VMs
- Zero critical VMs unprotected

NEXT STEPS:
1. Review unprotected VMs
2. Enable backup for critical VMs
3. Verify backup policies
4. Schedule regular compliance audits
5. Integrate with alerting
#>
