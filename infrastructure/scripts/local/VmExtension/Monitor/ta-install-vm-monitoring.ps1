<#
.SYNOPSIS
    Install Log Analytics monitoring agent extension on Azure VMs

.DESCRIPTION
    This script deploys the Microsoft Monitoring Agent (MMA) or OMS Agent extension
    to Azure VMs to enable centralized monitoring and logging. Essential for:
    - VM performance monitoring
    - Security and compliance logging
    - Update management
    - Change tracking and inventory
    - Azure Monitor integration
    
    The script:
    - Discovers all VMs in specified location
    - Automatically detects OS type (Windows/Linux)
    - Installs appropriate monitoring agent extension
    - Configures agent to report to Log Analytics workspace
    - Excludes AKS nodes automatically
    - Handles installation failures gracefully

.PARAMETER WorkspaceCustomerId
    The Log Analytics workspace ID (GUID) where agents will report

.PARAMETER WorkspaceSharedKey
    The primary or secondary key for the Log Analytics workspace

.PARAMETER Location
    Azure region to process VMs (e.g., "eastus", "westus2")

.PARAMETER ResourceGroupPattern
    Optional pattern to filter resource groups (e.g., "rg-prod-*")

.PARAMETER ExcludeAKS
    If true, excludes AKS node VMs (default: true)

.PARAMETER WhatIf
    If true, shows what would be done without making changes

.EXAMPLE
    .\Install-VmMonitoringExtension.ps1 -WorkspaceCustomerId "abc-123" -WorkspaceSharedKey "key" -Location "eastus"
    
    Installs monitoring agent on all VMs in East US

.EXAMPLE
    .\Install-VmMonitoringExtension.ps1 -WorkspaceCustomerId $wsId -WorkspaceSharedKey $wsKey -Location "westus2" -ResourceGroupPattern "rg-prod-*"
    
    Installs agent only on VMs in production resource groups

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Compute module
    - Az.OperationalInsights module
    - Virtual Machine Contributor role on VMs
    - Log Analytics workspace must exist
    
    Impact: Enables centralized monitoring and logging for all VMs.
    Foundation for Azure Monitor, Update Management, and Security Center.
    
    Note: Microsoft is transitioning from MMA to Azure Monitor Agent (AMA).
    Consider migrating to AMA for new deployments.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added parameters, progress tracking, better error handling, WhatIf support
    1.0.0 - Initial version with hardcoded values
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$WorkspaceCustomerId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$WorkspaceSharedKey,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Location,

    [Parameter(Mandatory=$false)]
    [String]$ResourceGroupPattern = "*",

    [Parameter(Mandatory=$false)]
    [bool]$ExcludeAKS = $true,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Initialize script
$ErrorActionPreference = "Continue"
$ExtensionName = 'MonitoringAgent'
$successCount = 0
$failureCount = 0
$skippedCount = 0

try {
    Write-Output "=========================================="
    Write-Output "VM Monitoring Agent Installation"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Location: $Location"
    Write-Output "Workspace ID: $WorkspaceCustomerId"
    Write-Output "Exclude AKS: $ExcludeAKS"
    Write-Output "WhatIf Mode: $WhatIf"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Configure extension settings
    # Public settings contain non-sensitive configuration
    $PublicSettings = @{
        workspaceId = $WorkspaceCustomerId
    }
    
    # Protected settings contain sensitive data (workspace key)
    $ProtectedSettings = @{
        workspaceKey = $WorkspaceSharedKey
    }

    # Get all VMs in the specified location
    Write-Output "Discovering VMs in location: $Location..."
    $allVMs = Get-AzVM -Location $Location -Status
    
    # Filter by resource group pattern if specified
    if ($ResourceGroupPattern -ne "*") {
        $allVMs = $allVMs | Where-Object { $_.ResourceGroupName -like $ResourceGroupPattern }
    }
    
    if (-not $allVMs -or $allVMs.Count -eq 0) {
        Write-Warning "No VMs found in location [$Location] matching criteria."
        return
    }
    
    Write-Output "Found $($allVMs.Count) VMs to process"
    Write-Output ""

    # Process each VM
    $vmCount = 0
    foreach ($vm in $allVMs) {
        $vmCount++
        Write-Output "[$vmCount/$($allVMs.Count)] Processing VM: $($vm.Name)"
        Write-Output "----------------------------------------"
        
        # Check if VM is an AKS node and should be excluded
        if ($ExcludeAKS -and $vm.Name.StartsWith("aks-")) {
            Write-Output "  Status: SKIPPED - AKS node VM"
            $skippedCount++
            Write-Output ""
            continue
        }
        
        # Determine OS type and appropriate extension
        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Output "  OS Type: $osType"
        
        switch ($osType) {
            'Linux' {
                $ExtensionType = 'OmsAgentForLinux'
                $TypeHandlerVersion = '1.7'
            }
            'Windows' {
                $ExtensionType = 'MicrosoftMonitoringAgent'
                $TypeHandlerVersion = '1.0'
            }
            default {
                Write-Warning "  Status: SKIPPED - Unknown OS type: $osType"
                $skippedCount++
                Write-Output ""
                continue
            }
        }
        
        Write-Output "  Extension Type: $ExtensionType"
        Write-Output "  Extension Version: $TypeHandlerVersion"
        
        # Check if extension already exists
        $existingExtension = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -Name $ExtensionName `
            -ErrorAction SilentlyContinue
        
        if ($existingExtension) {
            Write-Output "  Existing Extension: Found (will be updated)"
        } else {
            Write-Output "  Existing Extension: Not found (will be installed)"
        }
        
        # Install or update the extension
        if ($WhatIf) {
            Write-Output "  Action: WOULD INSTALL/UPDATE (WhatIf mode)"
            $successCount++
        } else {
            try {
                Write-Output "  Action: Installing/updating extension..."
                
                $result = Set-AzVMExtension `
                    -ResourceGroupName $vm.ResourceGroupName `
                    -VMName $vm.Name `
                    -Name $ExtensionName `
                    -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                    -ExtensionType $ExtensionType `
                    -TypeHandlerVersion $TypeHandlerVersion `
                    -Location $vm.Location `
                    -Settings $PublicSettings `
                    -ProtectedSettings $ProtectedSettings `
                    -ErrorAction Stop
                
                if ($result.IsSuccessStatusCode) {
                    Write-Output "  Result: SUCCESS - Extension installed/updated"
                    $successCount++
                } else {
                    Write-Warning "  Result: PARTIAL - Extension may not be fully configured"
                    Write-Output "  Status Code: $($result.StatusCode)"
                    $failureCount++
                }
                
            } catch {
                Write-Error "  Result: FAILED - $($_.Exception.Message)"
                Write-Output "  Recommendation: Check VM logs and ensure VM is running"
                $failureCount++
            }
        }
        
        Write-Output ""
    }

    # Summary
    Write-Output "=========================================="
    Write-Output "Installation Summary"
    Write-Output "=========================================="
    Write-Output "Total VMs Processed: $($allVMs.Count)"
    Write-Output "Successful: $successCount"
    Write-Output "Failed: $failureCount"
    Write-Output "Skipped: $skippedCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        TotalVMs = $allVMs.Count
        SuccessCount = $successCount
        FailureCount = $failureCount
        SkippedCount = $skippedCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during monitoring agent installation: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Compute, Az.OperationalInsights
   - Connect to Azure: Connect-AzAccount
   - Ensure Virtual Machine Contributor role on VMs
   - Log Analytics workspace must exist

2. Getting Workspace Credentials:
   # Get workspace ID and key
   $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName "rg-monitoring" -Name "law-prod"
   $workspaceId = $workspace.CustomerId
   $workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName "rg-monitoring" -Name "law-prod").PrimarySharedKey

3. Common Use Cases:
   - Initial deployment of monitoring to all VMs
   - Updating agent configuration (workspace change)
   - Ensuring monitoring compliance
   - Onboarding new VMs to monitoring

4. Extension Installation Time:
   - Windows VMs: 2-5 minutes per VM
   - Linux VMs: 1-3 minutes per VM
   - Large deployments: Consider batching or parallel execution

5. Troubleshooting:
   - If installation fails, check VM is running
   - Verify network connectivity to Log Analytics
   - Check VM extension logs in Azure Portal
   - Ensure workspace key is correct
   - Verify VM has outbound internet access

6. Migration to Azure Monitor Agent (AMA):
   Microsoft is deprecating MMA in favor of AMA. For new deployments:
   - Consider using Azure Monitor Agent instead
   - AMA provides better performance and features
   - Migration tools available for existing MMA deployments

EXPECTED RESULTS:
- Monitoring agent installed on all VMs
- VMs reporting to Log Analytics workspace
- Data flowing within 5-10 minutes
- VM insights and monitoring enabled

REAL-WORLD IMPACT:
Centralized monitoring is essential for:
- Performance troubleshooting
- Security incident detection
- Compliance and audit requirements
- Proactive issue detection
- Update management
- Change tracking

Without monitoring agents:
- No visibility into VM performance
- Security blind spots
- Manual troubleshooting required
- Compliance gaps

With monitoring agents:
- Centralized logging and metrics
- Automated alerting
- Security insights
- Simplified troubleshooting
- Compliance reporting

INTEGRATION:
This script integrates with:
- Azure Monitor (metrics and logs)
- Log Analytics (centralized logging)
- Update Management (patch compliance)
- Change Tracking (configuration changes)
- Security Center (security recommendations)
- Sentinel (security analytics)

NEXT STEPS:
1. Verify agents are reporting to workspace
2. Configure log collection rules
3. Set up monitoring alerts
4. Enable VM insights
5. Configure update management
6. Review security recommendations
#>
