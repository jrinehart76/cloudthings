<#
.SYNOPSIS
    Installs Log Analytics monitoring agent on VMs in a specific location via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook installs the Log Analytics monitoring agent (MMA/OMS) on all
    virtual machines in a specified Azure region. The runbook:
    
    - Discovers all VMs in the target location
    - Validates the Log Analytics workspace exists
    - Retrieves workspace ID and shared key for agent configuration
    - Checks for existing monitoring agents
    - Removes agents connected to wrong workspaces
    - Skips AKS nodes (automatically managed)
    - Installs the appropriate agent based on OS type (Windows/Linux)
    - Provides detailed status for each VM
    
    IMPORTANT: Microsoft is transitioning to Azure Monitor Agent (AMA). This script
    installs the legacy Log Analytics agent (MMA/OMS) which is still widely used but
    will eventually be deprecated. Consider migrating to AMA for new deployments.
    
    Designed for scheduled execution in Azure Automation to maintain monitoring coverage.

.PARAMETER WorkspaceName
    The name of the Log Analytics workspace to connect VMs to.
    The workspace must already exist in the subscription.
    
    Example: 'laws-prod-eastus'

.PARAMETER Location
    The Azure region to target for VM discovery and agent installation.
    Only VMs in this location will be processed.
    
    Example: 'eastus', 'westus2', 'southcentralus'

.EXAMPLE
    # Install Log Analytics agent on all VMs in East US
    .\ta-install-monitoring-runbook.ps1 -WorkspaceName 'laws-prod-eastus' -Location 'eastus'

.EXAMPLE
    # Install agent on VMs in West US 2
    .\ta-install-monitoring-runbook.ps1 -WorkspaceName 'laws-prod-westus2' -Location 'westus2'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Original Contributors: cherbison, dnite
    
    Prerequisites:
    - Azure Automation Account with Run As Account (Service Principal) configured
    - Service Principal must have Contributor or Virtual Machine Contributor role
    - Required PowerShell modules in Automation Account:
      * Az.Accounts
      * Az.Compute
      * Az.OperationalInsights
    - Log Analytics workspace must exist and be accessible
    
    Agent Versions:
    - Windows: MicrosoftMonitoringAgent (MMA) v1.0
    - Linux: OmsAgentForLinux v1.7
    
    Automatic Handling:
    - AKS nodes are automatically skipped (managed by AKS)
    - VMs with agents connected to wrong workspaces are reconfigured
    - VMs already connected to correct workspace are skipped
    
    Migration Note:
    - Microsoft is deprecating the Log Analytics agent (MMA/OMS)
    - New deployments should consider Azure Monitor Agent (AMA)
    - Existing MMA deployments will continue to work but plan migration
    
    Impact: Ensures comprehensive monitoring coverage for all VMs in a region,
    providing visibility into performance, security events, and operational health.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - 2020-01-16 - Initial version
#>

param (
    [Parameter(Mandatory=$True, HelpMessage="Name of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [String]$WorkspaceName,

    [Parameter(Mandatory=$True, HelpMessage="Azure region to target")]
    [ValidateNotNullOrEmpty()]
    [String]$Location
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all VMs
$ExtensionName = 'MonitoringAgent'
$successCount = 0
$failureCount = 0
$alreadyInstalledCount = 0
$skippedCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Install Log Analytics Agent Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Log Analytics Workspace: $WorkspaceName"
Write-Output "Target Location: $Location"
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

# Get Log Analytics workspace configuration
Write-Output "Retrieving Log Analytics workspace configuration..."
Try {
    # Find the workspace by name
    $Workspace = Get-AzOperationalInsightsWorkspace -ErrorAction Stop | 
        Where-Object {$_.Name -eq $WorkspaceName}
    
    if (!($Workspace)) {
        Write-Error "Log Analytics workspace '$WorkspaceName' not found in subscription."
        throw "Workspace not found"
    }
    
    Write-Output "Workspace: $($Workspace.Name)"
    Write-Output "Resource Group: $($Workspace.ResourceGroupName)"
    Write-Output "Location: $($Workspace.Location)"
    Write-Output "Workspace ID: $($Workspace.CustomerId)"
    
    # Get workspace shared keys for agent authentication
    $WorkspaceSharedKeys = Get-AzOperationalInsightsWorkspaceSharedKey `
        -Name $WorkspaceName `
        -ResourceGroupName $Workspace.ResourceGroupName `
        -WarningAction SilentlyContinue `
        -ErrorAction Stop
    
    if (!($WorkspaceSharedKeys)) {
        Write-Error "Failed to retrieve workspace shared keys for '$WorkspaceName'."
        throw "Workspace keys not found"
    }
    
    Write-Output "Workspace keys retrieved successfully"
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve workspace configuration: $_"
    throw
}

# Create configuration hash tables for agent installation
$PublicSettings = @{
    workspaceId = $Workspace.CustomerId
}
$ProtectedSettings = @{
    workspaceKey = $WorkspaceSharedKeys.PrimarySharedKey
}

# Get list of virtual machines in the target location
Write-Output "Discovering virtual machines in location: $Location"
Try {
    $Resources = Get-AzVM -Location $Location -Status -ErrorAction Stop
    Write-Output "Found $($Resources.Count) VMs in $Location"
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve VMs in location '$Location': $_"
    throw
}

# Validate VMs were found
if (!$Resources -or $Resources.Count -eq 0) {
    Write-Output "No VMs found in location '$Location'. Exiting."
    return
}

# Array to hold VMs that need agent installation
$VMs = @()

# Check for AKS nodes and VMs with existing monitoring agents
Write-Output "Checking existing agent installations..."
$count = 0
ForEach ($Resource in $Resources) {
    $count++
    $skip = $false
    
    # Show progress every 10 VMs
    if ($count % 10 -eq 0) {
        Write-Output "  Progress: $count/$($Resources.Count) VMs checked..."
    }
    
    # Skip AKS nodes (they are managed by AKS)
    if ($Resource.Name.StartsWith("aks-")) {
        Write-Output "  ⊘ Skipped: $($Resource.Name) (AKS node - automatically managed)"
        $skippedCount++
        continue
    }
    
    # Check if monitoring agent is already installed
    Try {
        $VMEx = Get-AzVMExtension `
            -ResourceGroupName $Resource.ResourceGroupName `
            -VMName $Resource.Name `
            -Name $ExtensionName `
            -ErrorAction "SilentlyContinue"
        
        if ($VMEx) {
            # Agent exists - check if it's connected to the correct workspace
            $workspaceId = $VMEx.PublicSettings | ConvertFrom-Json | Select-Object workspaceId -ExpandProperty workspaceId
            
            if ($workspaceId -ne $Workspace.CustomerId) {
                # Agent connected to wrong workspace - remove it
                Write-Output "  ⚠ $($Resource.Name): Connected to wrong workspace ($workspaceId)"
                Write-Output "    Removing incorrect agent..."
                
                Remove-AzVMExtension `
                    -ResourceGroupName $Resource.ResourceGroupName `
                    -VMName $Resource.Name `
                    -Name $ExtensionName `
                    -Force `
                    -ErrorAction "SilentlyContinue" | Out-Null
                
                if ($?) {
                    Write-Output "    ✓ Removed - will reinstall with correct workspace"
                } else {
                    Write-Warning "    ✗ Failed to remove agent - check VM logs"
                    $failureCount++
                    $skip = $true
                }
            }
            elseif ($workspaceId -eq $Workspace.CustomerId) {
                # Agent already connected to correct workspace - skip
                $alreadyInstalledCount++
                $skip = $true
            }
        }
    }
    Catch {
        Write-Warning "  Error checking $($Resource.Name): $_"
    }
    
    # Add VM to installation list if not skipped
    if (!$skip) {
        $VMs += $Resource
    }
}

Write-Output ""
Write-Output "VMs requiring agent installation: $($VMs.Count)"
Write-Output ""

# Install the monitoring agent on all remaining VMs
if ($VMs.Count -gt 0) {
    Write-Output "Installing Log Analytics agent on $($VMs.Count) VMs..."
    $installCount = 0
    
    ForEach ($Resource in $VMs) {
        $installCount++
        
        # Determine the correct extension type and version based on OS
        switch ($Resource.StorageProfile.OsDisk.OsType) {
            'Linux' {
                $ExtensionType = 'OmsAgentForLinux'
                $TypeHandlerVersion = '1.7'
            }
            'Windows' {
                $ExtensionType = 'MicrosoftMonitoringAgent'
                $TypeHandlerVersion = '1.0'
            }
            Default {
                Write-Warning "  ✗ $($Resource.Name): Unknown OS type - skipping"
                $failureCount++
                continue
            }
        }
        
        Write-Output "  [$installCount/$($VMs.Count)] Installing $ExtensionType on: $($Resource.Name)"
        
        Try {
            Set-AzVMExtension `
                -ResourceGroupName $Resource.ResourceGroupName `
                -VMName $Resource.Name `
                -Name $ExtensionName `
                -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                -ExtensionType $ExtensionType `
                -TypeHandlerVersion $TypeHandlerVersion `
                -Location $Resource.Location `
                -Settings $PublicSettings `
                -ProtectedSettings $ProtectedSettings `
                -ErrorAction Stop | Out-Null
            
            Write-Output "    ✓ Installation successful"
            $successCount++
        }
        Catch {
            Write-Warning "    ✗ Installation failed: $_"
            Write-Warning "    Check VM logs for details"
            $failureCount++
        }
    }
}
else {
    Write-Output "No VMs require agent installation."
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total VMs Processed: $($Resources.Count)"
Write-Output "Successfully Installed: $successCount"
Write-Output "Already Installed: $alreadyInstalledCount"
Write-Output "Skipped (AKS nodes): $skippedCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="