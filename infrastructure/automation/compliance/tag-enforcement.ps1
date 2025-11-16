<#
.SYNOPSIS
    Enforce required tags on Azure resources

.DESCRIPTION
    This runbook ensures all resources have required tags for cost allocation,
    compliance, and resource organization. Based on the principle from
    "From Base Camp to Summit": "The 'we'll organize things later' approach
    never works. Later never comes."
    
    The runbook:
    - Identifies resources missing required tags
    - Inherits tags from resource group where appropriate
    - Sends notifications to resource owners
    - Optionally auto-tags resources
    - Generates compliance reports

.PARAMETER RequiredTags
    Comma-separated list of required tag names (default: "CostCenter,Environment,Owner")

.PARAMETER InheritFromResourceGroup
    If true, inherit missing tags from resource group

.PARAMETER AutoTag
    If true, automatically apply tags. If false, only report violations.

.PARAMETER NotificationEmail
    Email address for compliance notifications

.PARAMETER ExcludeResourceTypes
    Comma-separated list of resource types to exclude

.EXAMPLE
    .\tag-enforcement.ps1 -RequiredTags "CostCenter,Owner" -AutoTag $false

.EXAMPLE
    .\tag-enforcement.ps1 -InheritFromResourceGroup $true -AutoTag $true

.NOTES
    Author: Jason Rinehart
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Impact: Enables cost allocation, resource organization, and compliance.
    Without proper tagging, organizations can't track spending or ownership.
    
    Target: 95%+ tag compliance across all resources
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$RequiredTags = "CostCenter,Environment,Owner",
    
    [Parameter(Mandatory=$false)]
    [bool]$InheritFromResourceGroup = $true,
    
    [Parameter(Mandatory=$false)]
    [bool]$AutoTag = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ExcludeResourceTypes = "microsoft.insights/components,microsoft.operationalinsights/workspaces"
)

$compliantCount = 0
$nonCompliantCount = 0
$taggedCount = 0
$errorCount = 0
$violations = @()

try {
    Write-Output "=========================================="
    Write-Output "Tag Enforcement Runbook"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Required Tags: $RequiredTags"
    Write-Output "Auto-Tag Mode: $AutoTag"
    Write-Output "Inherit from RG: $InheritFromResourceGroup"
    Write-Output ""

    # Connect to Azure
    Write-Output "Connecting to Azure..."
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected successfully"
    Write-Output ""

    # Parse required tags
    $requiredTagList = $RequiredTags -split "," | ForEach-Object { $_.Trim() }
    $excludeTypes = $ExcludeResourceTypes -split "," | ForEach-Object { $_.Trim().ToLower() }
    
    Write-Output "Discovering resources..."
    $allResources = Get-AzResource
    Write-Output "Found $($allResources.Count) total resources"
    Write-Output ""

    # Group resources by resource group for efficiency
    $resourcesByRG = $allResources | Group-Object -Property ResourceGroupName

    foreach ($rgGroup in $resourcesByRG) {
        $rgName = $rgGroup.Name
        Write-Output "Processing Resource Group: $rgName"
        Write-Output "----------------------------------------"
        
        # Get resource group tags
        $rg = Get-AzResourceGroup -Name $rgName
        $rgTags = $rg.Tags
        if ($null -eq $rgTags) { $rgTags = @{} }
        
        Write-Output "  Resource Group Tags: $($rgTags.Count) tags"
        
        foreach ($resource in $rgGroup.Group) {
            # Skip excluded resource types
            if ($excludeTypes -contains $resource.ResourceType.ToLower()) {
                continue
            }
            
            $resourceTags = $resource.Tags
            if ($null -eq $resourceTags) { $resourceTags = @{} }
            
            $missingTags = @()
            $tagsToAdd = @{}
            
            # Check each required tag
            foreach ($requiredTag in $requiredTagList) {
                if (-not $resourceTags.ContainsKey($requiredTag)) {
                    # Tag is missing
                    if ($InheritFromResourceGroup -and $rgTags.ContainsKey($requiredTag)) {
                        # Can inherit from resource group
                        $tagsToAdd[$requiredTag] = $rgTags[$requiredTag]
                        Write-Verbose "    $($resource.Name): Will inherit $requiredTag from RG"
                    } else {
                        # Cannot inherit - violation
                        $missingTags += $requiredTag
                    }
                }
            }
            
            # Determine compliance status
            if ($missingTags.Count -eq 0 -and $tagsToAdd.Count -eq 0) {
                # Fully compliant
                $compliantCount++
            } else {
                # Non-compliant
                $nonCompliantCount++
                
                # Record violation
                $violation = [PSCustomObject]@{
                    ResourceName = $resource.Name
                    ResourceType = $resource.ResourceType
                    ResourceGroup = $rgName
                    MissingTags = ($missingTags -join ", ")
                    InheritableTags = ($tagsToAdd.Keys -join ", ")
                    ResourceId = $resource.ResourceId
                }
                $violations += $violation
                
                # Auto-tag if enabled and we have tags to add
                if ($AutoTag -and $tagsToAdd.Count -gt 0) {
                    try {
                        Write-Output "    $($resource.Name): Adding tags: $($tagsToAdd.Keys -join ', ')"
                        
                        # Merge with existing tags
                        $updatedTags = $resourceTags.Clone()
                        foreach ($key in $tagsToAdd.Keys) {
                            $updatedTags[$key] = $tagsToAdd[$key]
                        }
                        
                        # Update resource tags
                        Update-AzTag -ResourceId $resource.ResourceId -Tag $updatedTags -Operation Merge | Out-Null
                        $taggedCount++
                        
                        # Re-check compliance after tagging
                        $stillMissing = @()
                        foreach ($requiredTag in $requiredTagList) {
                            if (-not $updatedTags.ContainsKey($requiredTag)) {
                                $stillMissing += $requiredTag
                            }
                        }
                        
                        if ($stillMissing.Count -eq 0) {
                            Write-Output "      Result: NOW COMPLIANT"
                            $compliantCount++
                            $nonCompliantCount--
                        } else {
                            Write-Output "      Result: PARTIALLY COMPLIANT (still missing: $($stillMissing -join ', '))"
                        }
                        
                    } catch {
                        Write-Error "      Result: FAILED to add tags - $_"
                        $errorCount++
                    }
                } elseif ($missingTags.Count -gt 0) {
                    Write-Output "    $($resource.Name): VIOLATION - Missing: $($missingTags -join ', ')"
                }
            }
        }
        Write-Output ""
    }

    # Calculate compliance percentage
    $totalResources = $compliantCount + $nonCompliantCount
    $compliancePercentage = if ($totalResources -gt 0) { 
        [math]::Round(($compliantCount / $totalResources) * 100, 2) 
    } else { 
        100 
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Tag Compliance Summary"
    Write-Output "=========================================="
    Write-Output "Total Resources: $totalResources"
    Write-Output "Compliant: $compliantCount"
    Write-Output "Non-Compliant: $nonCompliantCount"
    Write-Output "Auto-Tagged: $taggedCount"
    Write-Output "Errors: $errorCount"
    Write-Output "Compliance Rate: $compliancePercentage%"
    Write-Output ""
    
    # Show top violations
    if ($violations.Count -gt 0) {
        Write-Output "Top 10 Violations:"
        Write-Output "----------------------------------------"
        $violations | Select-Object -First 10 | ForEach-Object {
            Write-Output "  Resource: $($_.ResourceName)"
            Write-Output "  Type: $($_.ResourceType)"
            Write-Output "  Missing: $($_.MissingTags)"
            Write-Output ""
        }
    }
    
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Export violations to CSV for reporting
    if ($violations.Count -gt 0) {
        $csvPath = "tag-violations-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $violations | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Output "Violations exported to: $csvPath"
    }

    $summary = @{
        TotalResources = $totalResources
        CompliantCount = $compliantCount
        NonCompliantCount = $nonCompliantCount
        TaggedCount = $taggedCount
        ErrorCount = $errorCount
        CompliancePercentage = $compliancePercentage
        ViolationCount = $violations.Count
        ExecutionTime = Get-Date
    }
    
    return $summary

} catch {
    Write-Error "Fatal error in runbook: $_"
    throw
}

<#
USAGE NOTES:

1. Tagging Strategy:
   Required tags should include:
   - CostCenter: For cost allocation
   - Environment: For resource organization (prod, dev, test)
   - Owner: For accountability
   - Application: For grouping related resources
   - DataClassification: For security/compliance

2. Implementation Phases:
   Phase 1: Run in report-only mode (AutoTag = false)
   Phase 2: Enable inheritance (InheritFromResourceGroup = true)
   Phase 3: Enable auto-tagging (AutoTag = true)
   Phase 4: Enforce via Azure Policy (deny creation without tags)

3. Resource Group Tagging:
   Ensure resource groups have all required tags.
   Resources will inherit from their resource group.

4. Schedule:
   - Run daily for compliance monitoring
   - Run after hours for auto-tagging
   - Generate weekly compliance reports

5. Integration:
   - Export violations to CSV for reporting
   - Send to ServiceNow for remediation tickets
   - Dashboard in Power BI or Azure Workbook
   - Alert when compliance drops below threshold

EXPECTED RESULTS:
- 95%+ tag compliance within 30 days
- Accurate cost allocation by cost center
- Clear resource ownership
- Simplified resource management

REAL-WORLD IMPACT:
Without proper tagging:
- Cost allocation is impossible
- Resource ownership is unclear
- Compliance audits fail
- Resource management becomes chaos

With proper tagging:
- Accurate cost allocation and chargeback
- Clear accountability for resources
- Simplified compliance reporting
- Automated resource management

TARGET METRICS:
- 95%+ compliance rate
- <5% resources without owner tag
- 100% production resources tagged
- Zero untagged resources >30 days old
#>
