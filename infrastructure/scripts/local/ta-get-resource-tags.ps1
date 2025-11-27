
<#
.SYNOPSIS
    Export Azure resource tags to CSV for audit and compliance reporting

.DESCRIPTION
    This script generates a comprehensive CSV report of all Azure resources
    and their associated tags across all subscriptions. Essential for:
    - Tag compliance auditing
    - Cost allocation verification
    - Resource ownership tracking
    - Governance reporting
    
    The script:
    - Iterates through all accessible Azure subscriptions
    - Extracts resources and their tag values
    - Consolidates data into a single CSV file
    - Includes subscription context for each resource

.PARAMETER OutputPath
    Directory path where CSV files will be saved (default: current user's Documents folder)

.PARAMETER TagNames
    Comma-separated list of tag names to extract (default: ApplicationOwner,BusinessOwner,ApplicationName,FiscalYear)

.PARAMETER IncludeAllTags
    If true, includes all tags found on resources, not just specified ones

.EXAMPLE
    .\Get-Tagging.ps1
    
    Exports tags using default settings to Documents folder

.EXAMPLE
    .\Get-Tagging.ps1 -OutputPath "C:\Reports" -TagNames "CostCenter,Owner,Environment"
    
    Exports specific tags to custom location

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Resources module
    - Appropriate RBAC permissions (Reader or higher) on subscriptions
    
    Impact: Enables tag compliance monitoring and cost allocation tracking
    across entire Azure estate.

.VERSION
    2.0.0 - Complete rewrite with proper error handling and parameterization
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added parameters, error handling, dynamic paths, progress tracking
    1.0.0 - Initial version with hardcoded paths
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$TagNames = "ApplicationOwner,BusinessOwner,ApplicationName,FiscalYear",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeAllTags
)

# Initialize script
$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempFile = Join-Path $OutputPath "tagging-temp-$timestamp.csv"
$finalFile = Join-Path $OutputPath "tag_list-$timestamp.csv"

try {
    Write-Output "=========================================="
    Write-Output "Azure Resource Tagging Report"
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
    $subscriptions = Get-AzSubscription
    Write-Output "Found $($subscriptions.Count) subscriptions"
    Write-Output ""

    # Parse tag names to extract
    $tagList = $TagNames -split "," | ForEach-Object { $_.Trim() }
    Write-Output "Extracting tags: $($tagList -join ', ')"
    Write-Output ""

    # Initialize CSV with headers
    $headers = @("ResourceName", "ResourceGroupName") + $tagList + @("SubscriptionName", "SubscriptionId", "ResourceType", "Location")
    $headers -join "," | Out-File -FilePath $tempFile -Encoding UTF8

    # Track progress
    $totalResources = 0
    $subCount = 0

    # Process each subscription
    foreach ($sub in $subscriptions) {
        $subCount++
        Write-Output "[$subCount/$($subscriptions.Count)] Processing subscription: $($sub.Name)"
        Write-Output "----------------------------------------"
        
        try {
            # Set subscription context
            Set-AzContext -SubscriptionId $sub.Id | Out-Null
            
            # Get all resources in subscription
            Write-Output "  Retrieving resources..."
            $resources = Get-AzResource -ExpandProperties
            Write-Output "  Found $($resources.Count) resources"
            
            if ($resources.Count -eq 0) {
                Write-Output "  No resources found, skipping..."
                Write-Output ""
                continue
            }

            # Process each resource
            $resourceCount = 0
            foreach ($resource in $resources) {
                $resourceCount++
                
                # Show progress every 100 resources
                if ($resourceCount % 100 -eq 0) {
                    Write-Output "  Processed $resourceCount/$($resources.Count) resources..."
                }

                # Build row data
                $rowData = @{
                    ResourceName = $resource.Name
                    ResourceGroupName = $resource.ResourceGroupName
                    SubscriptionName = $sub.Name
                    SubscriptionId = $sub.Id
                    ResourceType = $resource.ResourceType
                    Location = $resource.Location
                }

                # Extract specified tags
                foreach ($tagName in $tagList) {
                    $tagValue = if ($resource.Tags -and $resource.Tags.ContainsKey($tagName)) {
                        $resource.Tags[$tagName]
                    } else {
                        ""
                    }
                    $rowData[$tagName] = $tagValue
                }

                # Build CSV row
                $row = @()
                $row += "`"$($rowData.ResourceName)`""
                $row += "`"$($rowData.ResourceGroupName)`""
                foreach ($tagName in $tagList) {
                    $row += "`"$($rowData[$tagName])`""
                }
                $row += "`"$($rowData.SubscriptionName)`""
                $row += "`"$($rowData.SubscriptionId)`""
                $row += "`"$($rowData.ResourceType)`""
                $row += "`"$($rowData.Location)`""

                # Append to temp file
                $row -join "," | Out-File -FilePath $tempFile -Append -Encoding UTF8
            }

            $totalResources += $resources.Count
            Write-Output "  Completed: $($resources.Count) resources processed"
            Write-Output ""

        } catch {
            Write-Warning "  Error processing subscription $($sub.Name): $_"
            Write-Output ""
            continue
        }
    }

    # Move temp file to final location
    if (Test-Path $tempFile) {
        Move-Item -Path $tempFile -Destination $finalFile -Force
        Write-Output "=========================================="
        Write-Output "Report Generation Complete"
        Write-Output "=========================================="
        Write-Output "Total Subscriptions: $($subscriptions.Count)"
        Write-Output "Total Resources: $totalResources"
        Write-Output "Output File: $finalFile"
        Write-Output ""
        Write-Output "End Time: $(Get-Date)"
        Write-Output "=========================================="
    } else {
        throw "Temporary file not found. Report generation may have failed."
    }

} catch {
    Write-Error "Fatal error generating tagging report: $_"
    
    # Clean up temp file if it exists
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install Az PowerShell modules: Install-Module -Name Az
   - Connect to Azure: Connect-AzAccount
   - Ensure you have Reader access to all subscriptions

2. Common Use Cases:
   - Tag compliance auditing
   - Cost allocation verification
   - Resource ownership tracking
   - Governance reporting
   - Preparing for tag enforcement

3. Output Analysis:
   - Import CSV into Excel or Power BI
   - Filter for missing tags
   - Identify resources without owners
   - Track tag compliance by subscription

4. Integration:
   - Schedule via Azure Automation for regular reports
   - Send output to SharePoint or blob storage
   - Integrate with Power BI for dashboards
   - Use with tag-enforcement.ps1 for remediation

5. Performance:
   - Large environments (1000+ resources) may take 5-10 minutes
   - Consider filtering by resource group or subscription
   - Run during off-peak hours for automation

EXPECTED RESULTS:
- CSV file with all resources and their tags
- Clear visibility into tag compliance
- Foundation for tag governance program
- Data for cost allocation and chargeback

REAL-WORLD IMPACT:
Tag reporting is the first step in establishing tag governance.
Organizations typically discover:
- 40-60% of resources missing required tags
- Inconsistent tag values (prod vs production vs prd)
- Resources without clear ownership
- Opportunities for cost optimization

This report enables:
- Targeted remediation efforts
- Tag standardization initiatives
- Improved cost allocation
- Better resource management
#>