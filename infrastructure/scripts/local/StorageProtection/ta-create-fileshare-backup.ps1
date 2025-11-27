<#
.SYNOPSIS
    Trigger on-demand backup for Azure File Shares in Recovery Services Vault

.DESCRIPTION
    This script triggers an on-demand backup for all Azure File Shares configured
    in a Recovery Services Vault with custom retention period. Essential for:
    - Pre-change backups before major updates
    - Compliance and audit requirements
    - Long-term retention beyond policy
    - Migration and disaster recovery preparation
    
    The script:
    - Sets Recovery Services Vault context
    - Discovers all file share backup items
    - Triggers on-demand backup with custom retention
    - Provides detailed logging of backup operations
    
    Real-world impact: Enables flexible backup scheduling beyond standard
    policies for compliance, pre-change protection, and long-term retention.

.PARAMETER RSVName
    Name of the Recovery Services Vault

.PARAMETER VaultRetention
    Number of days to retain this backup (beyond standard policy)

.PARAMETER ResourceGroupName
    Optional resource group name where vault resides (improves performance)

.EXAMPLE
    .\ta-create-fileshare-backup.ps1 -RSVName "rsv-prod-backup" -VaultRetention 90
    
    Triggers backup with 90-day retention

.EXAMPLE
    .\ta-create-fileshare-backup.ps1 -RSVName "rsv-prod-backup" -VaultRetention 365 -ResourceGroupName "rg-backup"
    
    Triggers backup with 1-year retention, specifying resource group

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.RecoveryServices module
    - Backup Contributor role on Recovery Services Vault
    - File shares must already be configured for backup
    - Recovery Services Vault must exist
    
    Impact: Provides flexible backup scheduling for compliance and
    pre-change protection beyond standard backup policies.
    
    Note: This triggers on-demand backups. Standard scheduled backups
    continue per configured policy.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, error handling, progress tracking
    1.0.0 - Initial version for automation runbooks
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true, HelpMessage="Recovery Services Vault name")]
    [ValidateNotNullOrEmpty()]
    [String]$RSVName,
    
    [Parameter(Mandatory=$true, HelpMessage="Retention period in days")]
    [ValidateRange(1, 9999)]
    [Int]$VaultRetention,
    
    [Parameter(Mandatory=$false)]
    [String]$ResourceGroupName
)
# Initialize script
$ErrorActionPreference = "Stop"
$backupCount = 0
$errorCount = 0
$skippedCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Azure File Share On-Demand Backup"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Recovery Services Vault: $RSVName"
    Write-Output "Retention Period: $VaultRetention days"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Calculate retention expiry date
    $currentDate = Get-Date
    $expiryDate = $currentDate.AddDays($VaultRetention)
    Write-Output "Backup Retention Details:"
    Write-Output "  Current Date: $currentDate"
    Write-Output "  Expiry Date: $expiryDate"
    Write-Output "  Retention Days: $VaultRetention"
    Write-Output ""

    # Get Recovery Services Vault
    Write-Output "Retrieving Recovery Services Vault..."
    if ($ResourceGroupName) {
        $vault = Get-AzRecoveryServicesVault -Name $RSVName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    } else {
        $vault = Get-AzRecoveryServicesVault -Name $RSVName -ErrorAction Stop
    }
    
    Write-Output "Vault: $($vault.Name)"
    Write-Output "Location: $($vault.Location)"
    Write-Output "Resource Group: $($vault.ResourceGroupName)"
    Write-Output "Subscription: $($vault.SubscriptionId)"
    Write-Output ""

    # Set vault context
    Write-Output "Setting vault context..."
    Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop | Out-Null
    Write-Output "Vault context set successfully"
    Write-Output ""

    # Get backup containers
    Write-Output "Discovering backup containers..."
    $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -ErrorAction Stop
    
    if (-not $containers -or $containers.Count -eq 0) {
        Write-Warning "No Azure Storage containers found in vault"
        Write-Output "This vault may not have any file shares configured for backup"
        return
    }
    
    Write-Output "Found $($containers.Count) storage container(s)"
    Write-Output ""

    # Process each container
    $containerCount = 0
    foreach ($container in $containers) {
        $containerCount++
        Write-Output "[$containerCount/$($containers.Count)] Processing container: $($container.FriendlyName)"
        Write-Output "----------------------------------------"
        
        try {
            # Get file share backup items in container
            $fileShares = Get-AzRecoveryServicesBackupItem -WorkloadType AzureFiles -Container $container -ErrorAction Stop
            
            if ($fileShares) {
                Write-Output "  Found $($fileShares.Count) file share(s) configured for backup"
                
                foreach ($share in $fileShares) {
                    try {
                        Write-Output "  Processing: $($share.Name)"
                        Write-Output "    Protection Status: $($share.ProtectionStatus)"
                        Write-Output "    Last Backup: $($share.LastBackupTime)"
                        
                        # Trigger on-demand backup
                        Write-Output "    Action: Triggering on-demand backup..."
                        $backupJob = Backup-AzRecoveryServicesBackupItem `
                            -Item $share `
                            -ExpiryDateTimeUTC $expiryDate `
                            -ErrorAction Stop
                        
                        Write-Output "    Result: SUCCESS - Backup job started"
                        Write-Output "    Job ID: $($backupJob.JobId)"
                        Write-Output "    Status: $($backupJob.Status)"
                        $backupCount++
                        
                    } catch {
                        Write-Warning "    Result: FAILED - $_"
                        $errorCount++
                    }
                    Write-Output ""
                }
            } else {
                Write-Output "  No file shares configured for backup in this container"
                $skippedCount++
            }
            
        } catch {
            Write-Warning "  Error processing container: $_"
            $errorCount++
        }
        
        Write-Output ""
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Backup Summary"
    Write-Output "=========================================="
    Write-Output "Containers Processed: $($containers.Count)"
    Write-Output "Backups Triggered: $backupCount"
    Write-Output "Containers Skipped: $skippedCount"
    Write-Output "Errors: $errorCount"
    Write-Output "Retention Period: $VaultRetention days"
    Write-Output "Expiry Date: $expiryDate"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        Success = $true
        BackupCount = $backupCount
        SkippedCount = $skippedCount
        ErrorCount = $errorCount
        RetentionDays = $VaultRetention
        ExpiryDate = $expiryDate
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during file share backup: $_"
    
    return @{
        Success = $false
        Error = $_.Exception.Message
        ExecutionTime = Get-Date
    }
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.RecoveryServices
   - Connect to Azure: Connect-AzAccount
   - Ensure Backup Contributor role on vault
   - File shares must already be configured for backup
   - Recovery Services Vault must exist

2. Backup vs. Snapshot:
   - Snapshots: Instant, incremental, short-term (days)
   - Backups: Managed by Azure Backup, long-term (years)
   - This script triggers Azure Backup (not snapshots)
   - Backups stored in Recovery Services Vault
   - Backups can be restored to any storage account

3. Retention Strategy:
   - Standard policy: Daily/weekly/monthly/yearly retention
   - On-demand backup: Custom retention beyond policy
   - Use for: Pre-change backups, compliance, long-term retention
   - Retention period: 1-9999 days (27+ years)

4. Common Use Cases:
   - Pre-change backups before major updates
   - Compliance requirements (quarterly, annual backups)
   - Long-term retention beyond standard policy
   - Migration preparation
   - Disaster recovery testing

5. Backup Job Monitoring:
   - Script triggers backup jobs (doesn't wait for completion)
   - Monitor job status in Azure Portal or PowerShell
   - Jobs typically complete in 5-30 minutes
   - Check job status: Get-AzRecoveryServicesBackupJob

EXPECTED RESULTS:
- On-demand backup triggered for all file shares
- Custom retention period applied
- Backup jobs started (not completed)
- Summary of triggered backups

REAL-WORLD IMPACT:
On-demand backups provide flexibility beyond standard policies:

Use Cases:
- Pre-change protection: Backup before major updates
- Compliance: Quarterly/annual backups for audit
- Long-term retention: Keep specific backups for years
- Migration: Backup before moving to new storage
- Testing: Create recovery points for DR testing

Benefits:
- Flexible retention beyond standard policy
- Compliance with regulatory requirements
- Protection before high-risk changes
- Simplified disaster recovery testing
- Cost-effective long-term retention

COST CONSIDERATIONS:
- Backup storage: ~$0.10-0.20 per GB per month
- Longer retention = higher costs
- Balance retention with compliance needs
- Review and delete old backups when no longer needed

COMPLIANCE REQUIREMENTS:
Many regulations require long-term backup retention:
- HIPAA: 6 years for healthcare data
- SOX: 7 years for financial records
- GDPR: Varies by data type and jurisdiction
- Industry-specific: May require 10+ years

AUTOMATION:
Schedule this script for:
- Pre-change backups (before deployments)
- Monthly compliance backups
- Quarterly audit backups
- Annual long-term retention backups

INTEGRATION:
- Azure Automation for scheduling
- Azure Monitor for backup job alerts
- Logic Apps for notification workflows
- ServiceNow for change management integration

NEXT STEPS:
1. Verify backup jobs completed successfully
2. Test restore process
3. Document backup and retention policies
4. Schedule regular on-demand backups
5. Monitor backup storage costs
6. Review and cleanup old backups
7. Integrate with change management process
#>