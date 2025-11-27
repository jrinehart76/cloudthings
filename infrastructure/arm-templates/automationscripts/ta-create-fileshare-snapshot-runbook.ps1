<#
.SYNOPSIS
    Creates Azure File Share snapshots and manages retention via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook creates point-in-time snapshots of Azure File Shares
    and automatically manages snapshot retention. The runbook:
    
    - Creates a new snapshot of the specified file share
    - Validates the snapshot was created successfully
    - Identifies snapshots older than the retention period (default: 7 days)
    - Automatically deletes expired snapshots to manage storage costs
    - Provides detailed logging of snapshot creation and cleanup
    
    Azure File Share snapshots provide:
    - Point-in-time recovery for accidental deletions or modifications
    - Protection against ransomware and data corruption
    - Zero-downtime backup capability (snapshots are instant)
    - Space-efficient storage (only changed blocks consume space)
    
    Typical Usage:
    - Schedule this runbook to run hourly for frequent recovery points
    - Adjust retention period based on compliance and recovery requirements
    - Use with Azure Backup for comprehensive file share protection
    
    Designed for scheduled execution in Azure Automation to maintain automated backups.

.PARAMETER storageAccountName
    The name of the Azure Storage Account containing the file share.
    
    Example: 'saprodeastus'

.PARAMETER storageAccountRG
    The name of the resource group containing the storage account.
    
    Example: 'rg-storage-prod'

.PARAMETER fileShareName
    The name of the Azure File Share to snapshot.
    
    Example: 'fileshare-data'

.EXAMPLE
    # Create snapshot of a file share (typically called by Azure Automation scheduler)
    .\ta-create-fileshare-snapshot-runbook.ps1 -storageAccountName 'saprodeastus' -storageAccountRG 'rg-storage-prod' -fileShareName 'fileshare-data'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Original Contributors: Kyle Thompson [CloudPlatformProvider]
    
    Prerequisites:
    - Azure Automation Account with Run As Account (Service Principal) configured
    - Service Principal must have Storage Account Contributor role
    - Required PowerShell modules in Automation Account:
      * Az.Accounts
      * Az.Storage
    - Storage account and file share must exist
    
    Retention Policy:
    - Default retention: 7 days
    - Snapshots older than 7 days are automatically deleted
    - Adjust retention by modifying the AddDays(-7) value in the script
    
    Scheduling Recommendations:
    - Hourly: For critical data requiring frequent recovery points
    - Daily: For standard business data
    - Consider Azure Backup for enterprise-grade file share protection
    
    Storage Costs:
    - Snapshots only consume storage for changed data (incremental)
    - Older snapshots may consume more space as data changes
    - Automatic cleanup helps manage storage costs
    
    Impact: Provides automated point-in-time recovery capability for Azure File Shares,
    protecting against accidental deletion, corruption, and ransomware. Essential for
    business continuity and data protection strategies.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added validation
    1.1.0 - Updated snapshot variable naming and removal command
    1.0.0 - Initial runbook creation
#>

Param(
    [Parameter(Mandatory = $true, HelpMessage = "Name of the storage account")]
    [ValidateNotNullOrEmpty()]
    [string]$storageAccountName,

    [Parameter(Mandatory = $true, HelpMessage = "Resource group containing the storage account")]
    [ValidateNotNullOrEmpty()]
    [string]$storageAccountRG,

    [Parameter(Mandatory = $true, HelpMessage = "Name of the file share to snapshot")]
    [ValidateNotNullOrEmpty()]
    [string]$fileShareName
)

# Initialize script variables
$ErrorActionPreference = "Stop"  # Stop on errors for snapshot operations
$retentionDays = 7  # Number of days to retain snapshots

# Output runbook start information
Write-Output "=========================================="
Write-Output "Create File Share Snapshot Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Storage Account: $storageAccountName"
Write-Output "Resource Group: $storageAccountRG"
Write-Output "File Share: $fileShareName"
Write-Output "Retention Period: $retentionDays days"
Write-Output ""

# Connect to Azure using Automation Account Run As Connection
Write-Output "Connecting to Azure..."
$ConnectionName = 'AzureRunAsConnection'

Try {
    # Get the automation connection asset
    $AutomationConnection = Get-AutomationConnection -Name $ConnectionName
    
    # Connect to Azure with the service principal
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal `
        -ErrorAction Stop
    
    # Get subscription context
    $context = Get-AzContext
    Write-Output "Connected to Azure"
    Write-Output "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
    Write-Output "Service Principal: $($AutomationConnection.ApplicationId)"
    Write-Output ""
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection '$ConnectionName' not found. Ensure the Automation Account has a Run As Account configured."
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
    else {
        Write-Error "Failed to connect to Azure: $_"
        throw $_.Exception
    }
}

# Get storage account and validate it exists
Write-Output "Validating storage account and file share..."
Try {
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $storageAccountRG -Name $storageAccountName -ErrorAction Stop
    Write-Output "Storage Account: $($storageAccount.StorageAccountName)"
    Write-Output "Location: $($storageAccount.Location)"
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve storage account '$storageAccountName' in resource group '$storageAccountRG': $_"
    throw
}

# Get file share and validate it exists
Try {
    $share = Get-AzStorageShare -Context $storageAccount.Context -Name $fileShareName -ErrorAction Stop
    Write-Output "File Share: $($share.Name)"
    Write-Output "Quota: $($share.Properties.Quota) GB"
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve file share '$fileShareName' in storage account '$storageAccountName': $_"
    throw
}

# Create new snapshot
Write-Output "Creating snapshot..."
Try {
    $newSnapshot = $share.Snapshot()
    
    # Validate snapshot was created successfully
    if ($newSnapshot -and $newSnapshot.IsSnapshot -eq $true) {
        Write-Output "✓ Snapshot created successfully"
        Write-Output "  Snapshot Name: $($newSnapshot.Name)"
        Write-Output "  Snapshot Time: $($newSnapshot.SnapshotTime)"
        Write-Output ""
    }
    else {
        Write-Error "Snapshot creation failed for file share '$($share.Name)'"
        throw "Snapshot validation failed"
    }
}
Catch {
    Write-Error "Failed to create snapshot: $_"
    throw
}

# Clean up old snapshots beyond retention period
Write-Output "Checking for expired snapshots (older than $retentionDays days)..."
Try {
    # Calculate cutoff date for snapshot retention
    $cutoffDate = [datetime]::UtcNow.AddDays(-$retentionDays)
    Write-Output "Cutoff Date: $cutoffDate (UTC)"
    
    # Get all snapshots older than retention period
    $expiredSnapshots = Get-AzStorageShare -Context $storageAccount.Context -ErrorAction Stop | 
        Where-Object {$_.IsSnapshot -eq $true -and $_.Name -eq $fileShareName -and $_.SnapshotTime -lt $cutoffDate}
    
    if (!$expiredSnapshots -or $expiredSnapshots.Count -eq 0) {
        Write-Output "No expired snapshots found for file share '$($share.Name)'"
    }
    else {
        Write-Output "Found $($expiredSnapshots.Count) expired snapshot(s) to delete"
        
        # Delete each expired snapshot
        $deletedCount = 0
        foreach ($snapshot in $expiredSnapshots) {
            Try {
                Write-Output "  Deleting snapshot from: $($snapshot.SnapshotTime)"
                Remove-AzStorageShare -Share $snapshot -ErrorAction Stop
                $deletedCount++
            }
            Catch {
                Write-Warning "  Failed to delete snapshot from $($snapshot.SnapshotTime): $_"
            }
        }
        
        Write-Output "✓ Deleted $deletedCount expired snapshot(s)"
    }
}
Catch {
    Write-Warning "Error during snapshot cleanup: $_"
    # Don't throw - snapshot creation was successful, cleanup is secondary
}

# Output summary
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "New Snapshot Created: $($newSnapshot.SnapshotTime)"
Write-Output "Retention Policy: $retentionDays days"
Write-Output "Storage Account: $storageAccountName"
Write-Output "File Share: $fileShareName"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="
