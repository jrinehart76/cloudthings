<#
.SYNOPSIS
    Enable Azure Backup for VMs using default backup policy

.DESCRIPTION
    This script enables Azure Backup protection for all VMs in the same region
    as the specified Recovery Services Vault using the default backup policy.
    Essential for:
    - Disaster recovery readiness
    - Data protection compliance
    - Business continuity planning
    - Ransomware protection
    
    The script:
    - Discovers all VMs in subscription
    - Filters VMs by vault location (backup must be in same region)
    - Checks if backup is already configured
    - Enables backup with default policy for unprotected VMs
    - Uses parallel job execution for performance
    
    Real-world impact: Ensures all VMs are protected against data loss,
    meeting RPO/RTO requirements and compliance mandates.

.PARAMETER RecoveryServicesVaultName
    Name of the Recovery Services Vault to use for backup

.PARAMETER Throttle
    Maximum number of parallel backup enablement jobs (default: 5)

.PARAMETER ResourceGroupPattern
    Optional pattern to filter VMs by resource group (e.g., "rg-prod-*")

.EXAMPLE
    .\ta-enable-vm-backup.ps1 -RecoveryServicesVaultName "rsv-prod-backup"
    
    Enables backup for all VMs in same region as vault

.EXAMPLE
    .\ta-enable-vm-backup.ps1 -RecoveryServicesVaultName "rsv-prod-backup" -Throttle 10
    
    Enables backup with higher parallelism for faster execution

.EXAMPLE
    .\ta-enable-vm-backup.ps1 -RecoveryServicesVaultName "rsv-prod-backup" -ResourceGroupPattern "rg-prod-*"
    
    Enables backup only for VMs in production resource groups

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Compute module
    - Az.RecoveryServices module
    - Backup Contributor role on VMs
    - Backup Contributor role on Recovery Services Vault
    - Recovery Services Vault must exist
    
    Impact: Ensures disaster recovery readiness and data protection compliance.
    Unprotected VMs are a critical risk for data loss and business continuity.
    
    Performance: Uses parallel job execution to enable backup on multiple VMs
    simultaneously, significantly reducing total execution time.

.VERSION
    2.0.0 - Enhanced documentation, error handling, and parameterization
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, better error handling, progress tracking
    1.0.0 - Initial version with basic functionality
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Name of the Recovery Services Vault")]
    [ValidateNotNullOrEmpty()]
    [string]$RecoveryServicesVaultName,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 20)]
    [int]$Throttle = 5,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupPattern = "*"
)

# Initialize script
$ErrorActionPreference = "Continue"
$enabledCount = 0
$skippedCount = 0
$errorCount = 0
$wrongRegionCount = 0

try {
    Write-Output "=========================================="
    Write-Output "VM Backup Enablement"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Recovery Services Vault: $RecoveryServicesVaultName"
    Write-Output "Parallel Jobs: $Throttle"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Get Recovery Services Vault
    Write-Output "Retrieving Recovery Services Vault..."
    $vault = Get-AzRecoveryServicesVault -Name $RecoveryServicesVaultName -ErrorAction Stop
    Write-Output "Vault: $($vault.Name)"
    Write-Output "Location: $($vault.Location)"
    Write-Output "Resource Group: $($vault.ResourceGroupName)"
    Write-Output ""

    # Set vault context
    Write-Output "Setting vault context..."
    Set-AzRecoveryServicesVaultContext -Vault $vault | Out-Null
    
    # Get default backup policy
    Write-Output "Retrieving default backup policy..."
    $defaultPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy" -ErrorAction Stop
    Write-Output "Policy: $($defaultPolicy.Name)"
    Write-Output "Schedule: $($defaultPolicy.SchedulePolicy.ScheduleRunFrequency)"
    Write-Output "Retention: $($defaultPolicy.RetentionPolicy.DailySchedule.DurationCountInDays) days"
    Write-Output ""

    # Get existing backup containers
    Write-Output "Checking existing backup configurations..."
    $backupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType 'AzureVM' -Status 'Registered'
    Write-Output "Found $($backupContainers.Count) VMs already configured for backup"
    Write-Output ""

    # Get all VMs
    Write-Output "Discovering VMs..."
    $allVMs = Get-AzVM -Status
    
    # Filter by resource group pattern if specified
    if ($ResourceGroupPattern -ne "*") {
        $allVMs = $allVMs | Where-Object { $_.ResourceGroupName -like $ResourceGroupPattern }
    }
    
    Write-Output "Found $($allVMs.Count) VMs to process"
    Write-Output ""

    # Define script block for parallel backup enablement
    $enableBackupJob = {
        param (
            $VMName,
            $VMResourceGroup,
            $VaultName,
            $PolicyName
        )
        
        try {
            # Set vault context in job
            $vault = Get-AzRecoveryServicesVault -Name $VaultName
            Set-AzRecoveryServicesVaultContext -Vault $vault | Out-Null
            
            # Get policy
            $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName
            
            # Enable backup
            Enable-AzRecoveryServicesBackupProtection `
                -Policy $policy `
                -Name $VMName `
                -ResourceGroupName $VMResourceGroup `
                -ErrorAction Stop
            
            return @{
                Success = $true
                VMName = $VMName
                Message = "Backup enabled successfully"
            }
        } catch {
            return @{
                Success = $false
                VMName = $VMName
                Message = $_.Exception.Message
            }
        }
    }

    # Initialize job collection
    $jobs = @()

    # Process each VM
    $vmCount = 0
    foreach ($vm in $allVMs) {
        $vmCount++
        Write-Output "[$vmCount/$($allVMs.Count)] Processing VM: $($vm.Name)"
        
        # Check if VM is in same region as vault
        if ($vm.Location -ne $vault.Location) {
            Write-Output "  Status: SKIPPED - VM in $($vm.Location), vault in $($vault.Location)"
            $wrongRegionCount++
            continue
        }
        
        # Check if backup already configured
        $existingBackup = $backupContainers | Where-Object { $_.FriendlyName -eq $vm.Name }
        if ($existingBackup) {
            Write-Output "  Status: SKIPPED - Backup already configured"
            $skippedCount++
            continue
        }
        
        # Check job queue and wait if at throttle limit
        $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
        if ($runningJobs.Count -ge $Throttle) {
            Write-Output "  Job queue full ($Throttle jobs running). Waiting for slot..."
            $runningJobs | Wait-Job -Any | Out-Null
        }
        
        # Start backup enablement job
        Write-Output "  Action: Starting backup enablement job..."
        $job = Start-Job -ScriptBlock $enableBackupJob -ArgumentList $vm.Name, $vm.ResourceGroupName, $vault.Name, $defaultPolicy.Name
        $jobs += $job
    }

    # Wait for all remaining jobs to complete
    if ($jobs.Count -gt 0) {
        Write-Output ""
        Write-Output "Waiting for all backup enablement jobs to complete..."
        $jobs | Wait-Job | Out-Null
        
        # Process job results
        Write-Output ""
        Write-Output "Processing job results..."
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            if ($result.Success) {
                Write-Output "  [$($result.VMName)] SUCCESS - $($result.Message)"
                $enabledCount++
            } else {
                Write-Warning "  [$($result.VMName)] FAILED - $($result.Message)"
                $errorCount++
            }
        }
        
        # Clean up jobs
        $jobs | Remove-Job
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Backup Enablement Summary"
    Write-Output "=========================================="
    Write-Output "Total VMs Processed: $($allVMs.Count)"
    Write-Output "Backup Enabled: $enabledCount"
    Write-Output "Already Protected: $skippedCount"
    Write-Output "Wrong Region: $wrongRegionCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        TotalVMs = $allVMs.Count
        EnabledCount = $enabledCount
        SkippedCount = $skippedCount
        WrongRegionCount = $wrongRegionCount
        ErrorCount = $errorCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during VM backup enablement: $_"
    
    # Clean up any running jobs
    if ($jobs) {
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -ErrorAction SilentlyContinue
    }
    
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Compute, Az.RecoveryServices
   - Connect to Azure: Connect-AzAccount
   - Ensure Backup Contributor role on VMs and vault
   - Recovery Services Vault must exist

2. Backup Policy:
   - Uses "DefaultPolicy" which includes:
     * Daily backups at 10:00 PM
     * 30 days retention for daily backups
     * 12 weeks retention for weekly backups
     * 60 months retention for monthly backups
     * 10 years retention for yearly backups
   - To use custom policy, modify script to specify policy name

3. Regional Considerations:
   - VMs must be in same region as Recovery Services Vault
   - Cross-region backup is not supported
   - Script automatically skips VMs in different regions

4. Performance:
   - Uses parallel job execution for faster processing
   - Default throttle of 5 jobs balances speed and resource usage
   - Increase throttle for faster execution in large environments
   - Each backup enablement takes 30-60 seconds

5. Common Issues:
   - "Vault not found" - Verify vault name and subscription
   - "Policy not found" - Ensure DefaultPolicy exists in vault
   - "Permission denied" - Verify Backup Contributor role
   - "VM already protected" - VM has existing backup configuration

EXPECTED RESULTS:
- All unprotected VMs in same region have backup enabled
- Default backup policy applied to all VMs
- Parallel execution completes in minutes, not hours
- Summary shows success/failure for each VM

REAL-WORLD IMPACT:
VM backup is critical for business continuity:

Without backup:
- Data loss from VM failures or corruption
- No recovery from ransomware attacks
- Compliance violations (HIPAA, SOC 2, etc.)
- Extended downtime during incidents
- Business impact from data loss

With backup:
- Point-in-time recovery for VMs
- Protection against ransomware
- Compliance with data protection requirements
- Reduced RTO/RPO
- Business continuity assurance

STATISTICS:
- 60% of companies without backup close within 6 months of major data loss
- Average cost of data loss: $1.5M per incident
- Average ransomware recovery time without backup: 3-4 weeks
- Average ransomware recovery time with backup: 1-2 days

COMPLIANCE REQUIREMENTS:
Many regulations require backup:
- HIPAA: Patient data must be backed up
- SOC 2: Data availability and recovery
- PCI-DSS: Backup of cardholder data
- GDPR: Data availability and integrity

NEXT STEPS:
1. Verify backup jobs are running successfully
2. Test restore process for critical VMs
3. Document backup policies and retention
4. Schedule regular backup testing
5. Monitor backup job success rates
6. Consider custom policies for different VM tiers
7. Implement backup alerting for failures
#>