<#
.SYNOPSIS
    Discover and inventory Azure File Shares across all subscriptions

.DESCRIPTION
    This script discovers all Azure Storage Accounts and their File Shares across
    all accessible subscriptions. Essential for:
    - File share inventory and documentation
    - Capacity planning
    - Backup configuration verification
    - Migration planning
    - Compliance auditing
    
    The script:
    - Queries all accessible Azure subscriptions
    - Discovers all storage accounts
    - Identifies file shares in each storage account
    - Handles permission errors gracefully
    - Exports results to CSV

.PARAMETER OutputPath
    Directory path where CSV report will be saved (default: user's Documents folder)

.PARAMETER SubscriptionFilter
    Optional subscription name pattern to filter (e.g., "prod*")

.PARAMETER IncludeEmptyAccounts
    If true, includes storage accounts with no file shares in report

.EXAMPLE
    .\ta-get-fileshares.ps1
    
    Discovers all file shares across all subscriptions

.EXAMPLE
    .\ta-get-fileshares.ps1 -OutputPath "C:\Reports" -SubscriptionFilter "prod*"
    
    Discovers file shares only in production subscriptions

.EXAMPLE
    .\ta-get-fileshares.ps1 -IncludeEmptyAccounts
    
    Includes storage accounts with no file shares in report

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Storage module
    - Reader access to subscriptions
    - Storage Account Contributor or Reader access
    
    Impact: Provides complete visibility into file share inventory for
    capacity planning, backup configuration, and compliance.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added parameters, error handling, progress tracking, CSV export
    1.0.0 - Initial version with basic discovery
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionFilter = "*",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeEmptyAccounts
)

# Initialize script
$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = Join-Path $OutputPath "FileShareInventory-$timestamp.csv"
$shareCount = 0
$storageAccountCount = 0
$permissionErrorCount = 0
$results = @()

try {
    Write-Output "=========================================="
    Write-Output "Azure File Share Discovery"
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

    # Get all accessible subscriptions
    Write-Output "Discovering subscriptions..."
    $allSubscriptions = Get-AzSubscription
    $subscriptions = $allSubscriptions | Where-Object { $_.Name -like $SubscriptionFilter }
    
    if ($subscriptions.Count -eq 0) {
        throw "No subscriptions found matching filter: $SubscriptionFilter"
    }
    
    Write-Output "Found $($subscriptions.Count) subscriptions matching filter"
    Write-Output ""

    # Process each subscription
    $subCount = 0
    foreach ($sub in $subscriptions) {
        $subCount++
        Write-Output "[$subCount/$($subscriptions.Count)] Processing subscription: $($sub.Name)"
        Write-Output "----------------------------------------"
        
        try {
            # Set subscription context
            Set-AzContext -Subscription $sub.Name -InformationAction SilentlyContinue | Out-Null
            
            # Get all storage accounts in subscription
            Write-Output "  Discovering storage accounts..."
            $storageAccounts = Get-AzStorageAccount -ErrorAction SilentlyContinue
            
            if (-not $storageAccounts -or $storageAccounts.Count -eq 0) {
                Write-Output "  No storage accounts found"
                Write-Output ""
                continue
            }
            
            Write-Output "  Found $($storageAccounts.Count) storage account(s)"
            
            # Process each storage account
            foreach ($sa in $storageAccounts) {
                $storageAccountCount++
                Write-Output "  Processing: $($sa.StorageAccountName)"
                
                try {
                    # Get file shares in storage account
                    $shares = Get-AzStorageShare -Context $sa.Context -ErrorAction Stop
                    
                    if ($shares -and $shares.Count -gt 0) {
                        Write-Output "    Found $($shares.Count) file share(s)"
                        
                        foreach ($share in $shares) {
                            $shareCount++
                            
                            # Get share properties
                            $shareProperties = $share.Properties
                            
                            # Add to results
                            $results += [PSCustomObject]@{
                                SubscriptionName = $sub.Name
                                SubscriptionId = $sub.Id
                                StorageAccountName = $sa.StorageAccountName
                                ResourceGroup = $sa.ResourceGroupName
                                Location = $sa.Location
                                ShareName = $share.Name
                                QuotaGB = $shareProperties.Quota
                                LastModified = $shareProperties.LastModified
                                AccessTier = $shareProperties.AccessTier
                                EnabledProtocols = $shareProperties.EnabledProtocols
                                ProvisioningState = $shareProperties.ProvisioningState
                            }
                        }
                    } else {
                        Write-Output "    No file shares found"
                        
                        # Include empty accounts if requested
                        if ($IncludeEmptyAccounts) {
                            $results += [PSCustomObject]@{
                                SubscriptionName = $sub.Name
                                SubscriptionId = $sub.Id
                                StorageAccountName = $sa.StorageAccountName
                                ResourceGroup = $sa.ResourceGroupName
                                Location = $sa.Location
                                ShareName = "No file shares"
                                QuotaGB = 0
                                LastModified = $null
                                AccessTier = $null
                                EnabledProtocols = $null
                                ProvisioningState = $null
                            }
                        }
                    }
                    
                } catch {
                    $errorMessage = $_.Exception.Message
                    
                    # Check if it's a permission error
                    if ($errorMessage -match "403" -or $errorMessage -match "Forbidden" -or $errorMessage -match "not authorized") {
                        Write-Warning "    Permission denied - cannot access file shares"
                        $permissionErrorCount++
                        
                        # Record permission error
                        $results += [PSCustomObject]@{
                            SubscriptionName = $sub.Name
                            SubscriptionId = $sub.Id
                            StorageAccountName = $sa.StorageAccountName
                            ResourceGroup = $sa.ResourceGroupName
                            Location = $sa.Location
                            ShareName = "Permission denied"
                            QuotaGB = 0
                            LastModified = $null
                            AccessTier = $null
                            EnabledProtocols = $null
                            ProvisioningState = $null
                        }
                    } else {
                        Write-Warning "    Error accessing storage account: $errorMessage"
                    }
                }
            }
            
        } catch {
            Write-Warning "  Error processing subscription $($sub.Name): $_"
        }
        
        Write-Output ""
    }

    # Export results to CSV
    Write-Output "Exporting results to CSV..."
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $csvFile -NoTypeInformation
    } else {
        Write-Warning "No file shares found to export"
    }

    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Discovery Summary"
    Write-Output "=========================================="
    Write-Output "Subscriptions Processed: $subCount"
    Write-Output "Storage Accounts Scanned: $storageAccountCount"
    Write-Output "File Shares Found: $shareCount"
    Write-Output "Permission Errors: $permissionErrorCount"
    Write-Output ""
    if ($results.Count -gt 0) {
        Write-Output "Output File: $csvFile"
    }
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        SubscriptionCount = $subCount
        StorageAccountCount = $storageAccountCount
        ShareCount = $shareCount
        PermissionErrorCount = $permissionErrorCount
        OutputFile = $csvFile
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during file share discovery: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Accounts, Az.Storage
   - Connect to Azure: Connect-AzAccount
   - Ensure Reader access to subscriptions
   - Ensure Storage Account Reader access

2. Common Use Cases:
   - File share inventory and documentation
   - Capacity planning and quota management
   - Backup configuration verification
   - Migration planning
   - Compliance auditing

3. Output Analysis:
   - CSV contains all file shares with properties
   - Sort by QuotaGB to identify large shares
   - Filter by SubscriptionName for specific environments
   - Identify shares without backup (cross-reference with backup report)
   - Check AccessTier for cost optimization opportunities

4. Integration:
   - Schedule via Azure Automation for regular inventory
   - Import into CMDB or documentation systems
   - Use with backup configuration scripts
   - Integrate with capacity planning tools

5. Permission Errors:
   - Script handles permission errors gracefully
   - Permission errors are logged in CSV
   - Ensure Storage Account Reader role for complete inventory
   - Some storage accounts may have firewall rules blocking access

EXPECTED RESULTS:
- CSV file with all file shares and their properties
- Complete inventory across all subscriptions
- Identification of permission issues
- Foundation for capacity planning and backup configuration

REAL-WORLD IMPACT:
File share inventory is essential for:
- Capacity planning and quota management
- Backup configuration and verification
- Cost optimization (tier selection)
- Migration planning
- Compliance and auditing

Without inventory:
- Unknown file shares consuming resources
- Backup gaps and compliance risks
- Capacity issues discovered too late
- Inefficient cost management

With inventory:
- Complete visibility into file share usage
- Proactive capacity planning
- Backup compliance verification
- Cost optimization opportunities
- Simplified migration planning

NEXT STEPS:
1. Review file shares for backup configuration
2. Identify shares approaching quota limits
3. Verify access tier for cost optimization
4. Document file share ownership
5. Schedule regular inventory updates
6. Cross-reference with backup reports
7. Implement capacity alerting
#>