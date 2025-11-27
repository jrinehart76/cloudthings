<#
.SYNOPSIS
    Remove Log Analytics monitoring agent from VMs connected to wrong workspace

.DESCRIPTION
    This script removes the Log Analytics (MMA/OMS) monitoring agent from VMs
    that are connected to a different workspace than specified. Used for:
    - Workspace migration and consolidation
    - Cleanup of incorrect agent configurations
    - Preparation for agent reconfiguration
    - Decommissioning old workspaces
    
    The script:
    - Discovers all VMs in specified location
    - Checks monitoring agent workspace connection
    - Removes agent if connected to different workspace
    - Skips VMs already connected to correct workspace
    - Skips AKS nodes automatically
    
    Real-world impact: Enables workspace migration and cleanup of
    misconfigured monitoring agents that send data to wrong workspace.

.PARAMETER WorkspaceCustomerId
    Customer ID (GUID) of the Log Analytics workspace to keep
    VMs connected to this workspace will be skipped

.PARAMETER Location
    Azure region to filter VMs (e.g., "eastus", "westus2")

.EXAMPLE
    .\ta-remove-vm-monitoring.ps1 -WorkspaceCustomerId "12345678-1234-1234-1234-123456789012" -Location "eastus"
    
    Removes monitoring agent from VMs in East US not connected to specified workspace

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Compute module
    - Virtual Machine Contributor role
    - VMs must exist in specified location
    
    Impact: Enables workspace migration and cleanup.
    Use with caution - removing monitoring agent will stop log collection
    until agent is reinstalled with correct workspace.
    
    WARNING: This removes monitoring agents. Ensure you have a plan to
    reinstall agents with correct workspace configuration.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, better error handling, progress tracking
    1.0.0 - Initial version for workspace migration
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Log Analytics workspace customer ID to keep")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceCustomerId,
    
    [Parameter(Mandatory=$true, HelpMessage="Azure region to filter VMs")]
    [ValidateNotNullOrEmpty()]
    [string]$Location
)

# Initialize script
$ErrorActionPreference = "Continue"
$extensionName = 'MonitoringAgent'
$removedCount = 0
$skippedCount = 0
$noAgentCount = 0
$aksNodeCount = 0
$errorCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Monitoring Agent Removal"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Target Workspace ID: $WorkspaceCustomerId"
    Write-Output "Location Filter: $Location"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Get all VMs in location
    Write-Output "Discovering VMs in location: $Location"
    $resources = Get-AzVM -Location $Location -Status -ErrorAction Stop
    
    if (-not $resources -or $resources.Count -eq 0) {
        Write-Warning "No VMs found in location: $Location"
        return
    }
    
    Write-Output "Found $($resources.Count) VM(s)"
    Write-Output ""

    # Process each VM
    $vmCount = 0
    foreach ($resource in $resources) {
        $vmCount++
        Write-Output "[$vmCount/$($resources.Count)] Processing VM: $($resource.Name)"
        Write-Output "  Resource Group: $($resource.ResourceGroupName)"
        
        # Skip AKS nodes
        if ($resource.Name.StartsWith("aks-")) {
            Write-Output "  Status: SKIPPED - AKS node (managed by AKS)"
            $aksNodeCount++
            Write-Output ""
            continue
        }
        
        # Check if monitoring agent extension exists
        try {
            $vmExtension = Get-AzVMExtension `
                -ResourceGroupName $resource.ResourceGroupName `
                -VMName $resource.Name `
                -Name $extensionName `
                -ErrorAction SilentlyContinue
            
            if (-not $vmExtension) {
                Write-Output "  Status: SKIPPED - No monitoring agent installed"
                $noAgentCount++
                Write-Output ""
                continue
            }
            
            # Get workspace ID from extension settings
            $publicSettings = $vmExtension.PublicSettings | ConvertFrom-Json
            $workspaceId = $publicSettings.workspaceId
            
            Write-Output "  Current Workspace: $workspaceId"
            
            # Check if connected to different workspace
            if ($workspaceId -ne $WorkspaceCustomerId) {
                Write-Output "  Action: Removing agent (connected to different workspace)"
                
                try {
                    Remove-AzVMExtension `
                        -ResourceGroupName $resource.ResourceGroupName `
                        -VMName $resource.Name `
                        -Name $extensionName `
                        -Force `
                        -ErrorAction Stop | Out-Null
                    
                    Write-Output "  Result: SUCCESS - Agent removed"
                    $removedCount++
                } catch {
                    Write-Warning "  Result: FAILED - $_"
                    $errorCount++
                }
            } else {
                Write-Output "  Status: SKIPPED - Already connected to target workspace"
                $skippedCount++
            }
            
        } catch {
            Write-Warning "  Error checking VM: $_"
            $errorCount++
        }
        
        Write-Output ""
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Removal Summary"
    Write-Output "=========================================="
    Write-Output "Total VMs Processed: $($resources.Count)"
    Write-Output "Agents Removed: $removedCount"
    Write-Output "Already Correct Workspace: $skippedCount"
    Write-Output "No Agent Installed: $noAgentCount"
    Write-Output "AKS Nodes Skipped: $aksNodeCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    
    if ($removedCount -gt 0) {
        Write-Output "NEXT STEPS:"
        Write-Output "  $removedCount VM(s) had monitoring agent removed"
        Write-Output "  Reinstall agents with correct workspace using ta-install-vm-monitoring.ps1"
        Write-Output ""
    }
    
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        TotalVMs = $resources.Count
        RemovedCount = $removedCount
        SkippedCount = $skippedCount
        NoAgentCount = $noAgentCount
        AKSNodeCount = $aksNodeCount
        ErrorCount = $errorCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during monitoring agent removal: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Compute
   - Connect to Azure: Connect-AzAccount
   - Ensure Virtual Machine Contributor role
   - Know the target workspace customer ID

2. Finding Workspace Customer ID:
   # Via Azure Portal
   - Navigate to Log Analytics workspace
   - Go to Agents management
   - Copy Workspace ID (customer ID)
   
   # Via PowerShell
   $workspace = Get-AzOperationalInsightsWorkspace -Name "law-prod" -ResourceGroupName "rg-monitoring"
   $workspace.CustomerId

3. Use Cases:
   - Workspace migration and consolidation
   - Cleanup of misconfigured agents
   - Decommissioning old workspaces
   - Preparation for agent reconfiguration
   - Multi-workspace cleanup

4. What Gets Removed:
   - Log Analytics agent (MMA/OMS) extension
   - Connection to old workspace
   - Log collection stops immediately
   - Historical data remains in old workspace

5. What Doesn't Get Removed:
   - Dependency Agent (separate extension)
   - Diagnostics extension
   - Other VM extensions
   - VM itself

EXPECTED RESULTS:
- Monitoring agents removed from VMs connected to wrong workspace
- VMs connected to correct workspace are skipped
- AKS nodes automatically skipped
- Summary of removal actions

REAL-WORLD IMPACT:
Workspace migration is common during:

Scenarios:
- Consolidating multiple workspaces
- Moving to new subscription
- Changing workspace region
- Decommissioning old infrastructure
- Fixing misconfigured agents

Without this script:
- Manual removal per VM (time-consuming)
- Risk of removing from correct workspace
- Difficult to track progress
- Error-prone process

With this script:
- Automated removal from wrong workspace
- Safe (skips correct workspace)
- Progress tracking
- Consistent results

MIGRATION WORKFLOW:
Step 1: Identify target workspace customer ID
Step 2: Run this script to remove old agents
        .\ta-remove-vm-monitoring.ps1 -WorkspaceCustomerId "new-workspace-id" -Location "eastus"
Step 3: Reinstall agents with new workspace
        .\ta-install-vm-monitoring.ps1 -WorkspaceId "new-workspace-id" -WorkspaceKey "key"
Step 4: Verify agents reporting to new workspace
Step 5: Decommission old workspace after data retention period

SAFETY CONSIDERATIONS:
- Script only removes agents from DIFFERENT workspace
- VMs already on target workspace are skipped
- AKS nodes automatically skipped
- No data loss (historical data remains in old workspace)
- Reinstall agents promptly to resume monitoring

TROUBLESHOOTING:
Common Issues:
- "VM not found" - Verify location filter
- "Permission denied" - Verify VM Contributor role
- "Extension not found" - VM doesn't have monitoring agent
- "Removal failed" - Check VM logs for details

Verification:
- Check VM extensions: Get-AzVMExtension
- Verify workspace connection removed
- Check old workspace for agent heartbeat (should stop)
- Reinstall agent and verify new workspace connection

NEXT STEPS:
1. Verify agents removed successfully
2. Reinstall agents with correct workspace
3. Verify agents reporting to new workspace
4. Update monitoring dashboards
5. Decommission old workspace after retention period
6. Document workspace migration
#>