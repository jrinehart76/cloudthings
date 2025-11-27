<#
.SYNOPSIS
    Create Azure File Share snapshot and manage snapshot retention

.DESCRIPTION
    This script creates a point-in-time snapshot of an Azure File Share and
    automatically manages snapshot retention by deleting snapshots older than
    the specified retention period. Essential for:
    - Data protection and recovery
    - Point-in-time restore capability
    - Protection against accidental deletion
    - Ransomware recovery
    - Compliance requirements
    
    The script:
    - Creates a new snapshot of the specified file share
    - Verifies snapshot creation success
    - Identifies snapshots older than retention period
    - Automatically deletes old snapshots
    - Provides detailed logging of all actions
    
    Real-world impact: Provides cost-effective, instant recovery capability
    for file shares without the overhead of full backups.

.PARAMETER StorageAccountName
    Name of the Azure Storage Account containing the file share

.PARAMETER StorageAccountRG
    Resource group name where the storage account resides

.PARAMETER FileShareName
    Name of the file share to snapshot

.PARAMETER RetentionDays
    Number of days to retain snapshots (default: 7)

.EXAMPLE
    .\ta-create-fileshare-snapshot.ps1 -StorageAccountName "stgprod01" -StorageAccountRG "rg-storage" -FileShareName "data"
    
    Creates snapshot with default 7-day retention

.EXAMPLE
    .\ta-create-fileshare-snapshot.ps1 -StorageAccountName "stgprod01" -StorageAccountRG "rg-storage" -FileShareName "data" -RetentionDays 30
    
    Creates snapshot with 30-day retention

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Storage module
    - Storage Account Contributor role
    - Storage account and file share must exist
    
    Impact: Provides instant recovery capability for file shares.
    Snapshots are incremental and cost-effective, storing only changed data.
    
    Cost: Snapshots only charge for differential data, typically 5-10% of
    original share size per snapshot.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, error handling, configurable retention
    1.0.0 - Initial version with hardcoded 7-day retention
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, HelpMessage="Storage account name")]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true, HelpMessage="Resource group name")]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountRG,

    [Parameter(Mandatory=$true, HelpMessage="File share name")]
    [ValidateNotNullOrEmpty()]
    [string]$FileShareName,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7
) 

# Initialize script
$ErrorActionPreference = "Stop"
$deletedCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Azure File Share Snapshot Creation"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Storage Account: $StorageAccountName"
    Write-Output "Resource Group: $StorageAccountRG"
    Write-Output "File Share: $FileShareName"
    Write-Output "Retention: $RetentionDays days"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Get storage account
    Write-Output "Retrieving storage account..."
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -Name $StorageAccountName -ErrorAction Stop
    Write-Output "Storage Account: $($storageAccount.StorageAccountName)"
    Write-Output "Location: $($storageAccount.Location)"
    Write-Output "SKU: $($storageAccount.Sku.Name)"
    Write-Output ""

    # Get file share
    Write-Output "Retrieving file share..."
    $share = Get-AzStorageShare -Context $storageAccount.Context -Name $FileShareName -ErrorAction Stop
    Write-Output "File Share: $($share.Name)"
    Write-Output "Quota: $($share.Properties.Quota) GB"
    Write-Output "Last Modified: $($share.Properties.LastModified)"
    Write-Output ""

    # Create snapshot
    Write-Output "Creating snapshot..."
    $newSnapshot = $share.Snapshot()
    
    # Verify snapshot creation
    if ($newSnapshot -and $newSnapshot.IsSnapshot -eq $true) {
        Write-Output "SUCCESS: Snapshot created"
        Write-Output "  Snapshot Name: $($newSnapshot.Name)"
        Write-Output "  Snapshot Time: $($newSnapshot.SnapshotTime)"
        Write-Output "  Is Snapshot: $($newSnapshot.IsSnapshot)"
    } else {
        throw "Snapshot creation failed for share [$FileShareName]"
    }
    Write-Output ""

    # Calculate retention cutoff date
    $retentionCutoff = [datetime]::UtcNow.AddDays(-$RetentionDays)
    Write-Output "Managing snapshot retention..."
    Write-Output "Retention Policy: Delete snapshots older than $RetentionDays days"
    Write-Output "Cutoff Date: $retentionCutoff"
    Write-Output ""

    # Get all snapshots for this share
    Write-Output "Discovering existing snapshots..."
    $allSnapshots = Get-AzStorageShare -Context $storageAccount.Context | 
        Where-Object { $_.IsSnapshot -eq $true -and $_.Name -eq $FileShareName }
    
    Write-Output "Found $($allSnapshots.Count) total snapshot(s) for this share"
    
    # Filter snapshots older than retention period
    $oldSnapshots = $allSnapshots | Where-Object { $_.SnapshotTime -lt $retentionCutoff }
    
    if ($oldSnapshots -and $oldSnapshots.Count -gt 0) {
        Write-Output "Found $($oldSnapshots.Count) snapshot(s) exceeding retention period"
        Write-Output ""
        
        foreach ($oldSnapshot in $oldSnapshots) {
            try {
                $age = ([datetime]::UtcNow - $oldSnapshot.SnapshotTime).Days
                Write-Output "  Deleting snapshot from $($oldSnapshot.SnapshotTime) (age: $age days)"
                Remove-AzStorageShare -Share $oldSnapshot -Force -ErrorAction Stop
                $deletedCount++
                Write-Output "    Result: DELETED"
            } catch {
                Write-Warning "    Result: FAILED - $_"
            }
        }
    } else {
        Write-Output "No snapshots found exceeding retention period"
    }
    Write-Output ""

    # Get current snapshot count after cleanup
    $remainingSnapshots = Get-AzStorageShare -Context $storageAccount.Context | 
        Where-Object { $_.IsSnapshot -eq $true -and $_.Name -eq $FileShareName }

    # Summary
    Write-Output "=========================================="
    Write-Output "Snapshot Summary"
    Write-Output "=========================================="
    Write-Output "New Snapshot Created: Yes"
    Write-Output "Snapshot Time: $($newSnapshot.SnapshotTime)"
    Write-Output "Old Snapshots Deleted: $deletedCount"
    Write-Output "Remaining Snapshots: $($remainingSnapshots.Count)"
    Write-Output "Retention Period: $RetentionDays days"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        Success = $true
        SnapshotCreated = $true
        SnapshotTime = $newSnapshot.SnapshotTime
        DeletedCount = $deletedCount
        RemainingCount = $remainingSnapshots.Count
        RetentionDays = $RetentionDays
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during snapshot creation: $_"
    
    return @{
        Success = $false
        SnapshotCreated = $false
        Error = $_.Exception.Message
        ExecutionTime = Get-Date
    }
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Storage
   - Connect to Azure: Connect-AzAccount
   - Ensure Storage Account Contributor role
   - Storage account and file share must exist

2. Snapshot Characteristics:
   - Snapshots are read-only, point-in-time copies
   - Incremental: Only changed data is stored
   - Instant creation (no data copy required)
   - Can be used for file-level restore
   - Retained even if share is deleted (until snapshot deleted)

3. Retention Strategy:
   - Default: 7 days (suitable for short-term recovery)
   - Recommended for production: 30 days
   - Compliance requirements may dictate longer retention
   - Balance retention with storage costs

4. Cost Optimization:
   - Snapshots only charge for differential data
   - Typical cost: 5-10% of original share size per snapshot
   - Older snapshots may cost more as data diverges
   - Regular cleanup reduces costs

5. Recovery Process:
   To restore from snapshot:
   a. Browse snapshot via Azure Portal or PowerShell
   b. Copy needed files back to share
   c. Or restore entire share from snapshot
   d. Snapshots can be mounted as read-only shares

EXPECTED RESULTS:
- New snapshot created successfully
- Old snapshots deleted per retention policy
- Detailed logging of all actions
- Summary of snapshot status

REAL-WORLD IMPACT:
File share snapshots provide critical recovery capability:

Without snapshots:
- No recovery from accidental deletion
- No point-in-time restore capability
- Ransomware can destroy all data
- Extended downtime during incidents

With snapshots:
- Instant recovery from accidental deletion
- Point-in-time restore capability
- Protection against ransomware
- Minimal RTO (minutes vs. hours)
- Cost-effective protection

STATISTICS:
- 60% of file share data loss is from accidental deletion
- Average recovery time with snapshots: 5-15 minutes
- Average recovery time without snapshots: 4-8 hours
- Snapshot storage cost: 5-10% of original data size

USE CASES:
- Accidental file deletion recovery
- Ransomware protection and recovery
- Testing and development (restore to known state)
- Compliance and audit requirements
- Pre-change snapshots for rollback

AUTOMATION:
Schedule this script to run:
- Hourly for critical shares
- Daily for standard shares
- Weekly for archival shares
- Before major changes or updates

INTEGRATION:
- Azure Automation runbooks for scheduling
- Azure Monitor for snapshot creation alerts
- Logic Apps for notification workflows
- Azure Backup for long-term retention

NEXT STEPS:
1. Schedule regular snapshot creation
2. Test restore process
3. Document recovery procedures
4. Monitor snapshot storage costs
5. Adjust retention based on requirements
6. Consider Azure Backup for long-term retention
#>
