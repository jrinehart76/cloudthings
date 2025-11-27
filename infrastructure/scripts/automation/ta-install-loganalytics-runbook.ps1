<#
.SYNOPSIS
    Installs Log Analytics agent (MMA/OMS) on Azure VMs via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook installs the Log Analytics monitoring agent on Azure
    virtual machines to enable centralized log collection and monitoring. The agent:
    
    - Collects performance metrics and event logs from VMs
    - Sends data to a Log Analytics workspace for analysis
    - Enables VM Insights, Update Management, and Change Tracking
    - Supports both Windows (MicrosoftMonitoringAgent) and Linux (OmsAgentForLinux)
    
    The runbook:
    - Validates the Log Analytics workspace exists
    - Retrieves workspace ID and shared key for agent configuration
    - Discovers all VMs in the subscription or specific resource group
    - Checks if the monitoring agent is already installed
    - Installs the appropriate agent based on OS type (Windows/Linux)
    - Skips VMs that already have the agent installed
    
    IMPORTANT: Microsoft is transitioning to Azure Monitor Agent (AMA). This script
    installs the legacy Log Analytics agent (MMA/OMS) which is still widely used but
    will eventually be deprecated. Consider migrating to AMA for new deployments.
    
    Designed for scheduled execution in Azure Automation to maintain monitoring coverage.

.PARAMETER WorkspaceName
    The name of the Log Analytics workspace to connect VMs to.
    The workspace must already exist in the subscription.
    
    Example: 'laws-prod-eastus'

.PARAMETER ResourceGroupName
    Optional. The name of a specific resource group to target.
    If not specified, the runbook will process all VMs in the subscription.
    
    Example: 'rg-production-vms'

.EXAMPLE
    # Install Log Analytics agent on all VMs in subscription
    .\ta-install-loganalytics-runbook.ps1 -WorkspaceName 'laws-prod-eastus'

.EXAMPLE
    # Install agent on VMs in a specific resource group
    .\ta-install-loganalytics-runbook.ps1 -WorkspaceName 'laws-prod-eastus' -ResourceGroupName 'rg-production-vms'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
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
    
    Migration Note:
    - Microsoft is deprecating the Log Analytics agent (MMA/OMS)
    - New deployments should consider Azure Monitor Agent (AMA)
    - Existing MMA deployments will continue to work but plan migration
    - See: https://docs.microsoft.com/azure/azure-monitor/agents/azure-monitor-agent-migration
    
    Impact: Enables comprehensive monitoring and logging for VMs, providing visibility
    into performance, security events, and operational health. Essential for VM Insights,
    Update Management, Change Tracking, and Security Center integration.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - 2019-07-02 - Initial version
#>

param (
    [Parameter(Mandatory=$True, HelpMessage="Name of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [String]$WorkspaceName,

    [Parameter(Mandatory=$False, HelpMessage="Optional resource group name to limit scope")]
    [String]$ResourceGroupName
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all VMs
$ExtensionName = 'MonitoringAgent'
$successCount = 0
$failureCount = 0
$alreadyInstalledCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Install Log Analytics Agent Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Log Analytics Workspace: $WorkspaceName"
if ($ResourceGroupName) {
    Write-Output "Target Resource Group: $ResourceGroupName"
} else {
    Write-Output "Target Scope: All VMs in subscription"
}
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
# Public settings contain the workspace ID (not sensitive)
$PublicSettings = @{
    workspaceId = $Workspace.CustomerId
}

# Protected settings contain the workspace key (sensitive - encrypted during transmission)
$ProtectedSettings = @{
    workspaceKey = $WorkspaceSharedKeys.PrimarySharedKey
}

# Get list of virtual machines based on scope
Write-Output "Discovering virtual machines..."
Try {
    if ($ResourceGroupName) {
        $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        Write-Output "Found $($VMs.Count) VMs in resource group: $ResourceGroupName"
    }
    else {
        $VMs = Get-AzVM -ErrorAction Stop
        Write-Output "Found $($VMs.Count) VMs in subscription"
    }
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve VMs: $_"
    throw
}

# Validate VMs were found
if (!($VMs) -or $VMs.Count -eq 0) {
    Write-Output "No VMs found in the specified scope. Exiting."
    return
}

# Process each VM to install Log Analytics agent
Write-Output "Processing VMs for Log Analytics agent installation..."
$count = 0
ForEach ($VM in $VMs) {
    $count++
    
    # Show progress every 10 VMs
    if ($count % 10 -eq 0) {
        Write-Output "  Progress: $count/$($VMs.Count) VMs processed..."
    }
    
    Try {
        # Get existing extensions on the VM
        $Extensions = Get-AzVMExtension -VMName $VM.Name -ResourceGroupName $VM.ResourceGroupName -ErrorAction Stop
        
        # Determine the correct extension type and version based on OS
        Switch ($VM.StorageProfile.OsDisk.OsType) {
            'Linux' {
                $ExtensionType = 'OmsAgentForLinux'
                $TypeHandlerVersion = '1.7'
            }
            'Windows' {
                $ExtensionType = 'MicrosoftMonitoringAgent'
                $TypeHandlerVersion = '1.0'
            }
            Default {
                Write-Warning "  ⚠ Skipped $($VM.Name): Unknown OS type"
                $failureCount++
                continue
            }
        }
        
        # Check if the monitoring agent is already installed
        if (!($Extensions.ExtensionType -imatch $ExtensionType)) {
            # Agent not installed - install it
            Try {
                Set-AzVMExtension `
                    -ResourceGroupName $VM.ResourceGroupName `
                    -VMName $VM.Name `
                    -Name $ExtensionName `
                    -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                    -ExtensionType $ExtensionType `
                    -TypeHandlerVersion $TypeHandlerVersion `
                    -Location $VM.Location `
                    -Settings $PublicSettings `
                    -ProtectedSettings $ProtectedSettings `
                    -ErrorAction Stop | Out-Null
                
                Write-Output "  ✓ Installed $ExtensionType on: $($VM.Name) ($($VM.StorageProfile.OsDisk.OsType))"
                $successCount++
            }
            Catch {
                Write-Warning "  ✗ Failed to install agent on $($VM.Name): $_"
                $failureCount++
            }
        } else {
            # Agent already installed
            $alreadyInstalledCount++
        }
    }
    Catch {
        Write-Warning "  ✗ Error processing $($VM.Name): $_"
        $failureCount++
    }
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total VMs Processed: $($VMs.Count)"
Write-Output "Successfully Installed: $successCount"
Write-Output "Already Installed: $alreadyInstalledCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="