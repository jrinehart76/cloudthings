<#
.SYNOPSIS
    Installs Dependency Agent for VM Insights via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook installs the Dependency Agent on Azure virtual machines
    to enable VM Insights service map and dependency visualization. The Dependency Agent:
    
    - Discovers network connections and dependencies between VMs and external services
    - Enables the VM Insights Map feature in Azure Monitor
    - Provides visibility into application architecture and communication patterns
    - Helps identify performance bottlenecks and failed connections
    - Supports both Windows and Linux VMs
    
    The runbook:
    - Validates VMs are running (powered on)
    - Checks that the Log Analytics agent (prerequisite) is already installed
    - Verifies the Dependency Agent is not already installed
    - Installs the appropriate agent based on OS type (Windows/Linux)
    - Skips VMs that don't meet prerequisites
    
    CRITICAL INSTALLATION ORDER (Linux):
    On Linux VMs, the Log Analytics agent MUST be installed before the Dependency Agent.
    Installing in the wrong order will cause the Dependency Agent installation to fail.
    Windows VMs can install agents in any order.
    
    Designed for scheduled execution in Azure Automation to maintain VM Insights coverage.

.PARAMETER ResourceGroupName
    Optional. The name of a specific resource group to target.
    If not specified, the runbook will process all VMs in the subscription.
    
    Default: 'rg-int'
    
    Example: 'rg-production-vms'

.EXAMPLE
    # Install Dependency Agent on all VMs in subscription
    .\ta-install-dependency-runbook.ps1

.EXAMPLE
    # Install agent on VMs in a specific resource group
    .\ta-install-dependency-runbook.ps1 -ResourceGroupName 'rg-production-vms'

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
    - Log Analytics agent (MMA/OMS) must already be installed on VMs
    - VMs must be in running state (powered on)
    
    Installation Order (CRITICAL for Linux):
    1. Log Analytics agent (MMA/OMS) - MUST be installed first
    2. Dependency Agent - Install after Log Analytics agent
    
    On Linux, installing Dependency Agent before Log Analytics agent will fail.
    On Windows, order doesn't matter but Log Analytics agent is still required.
    
    Agent Versions:
    - Windows: DependencyAgentWindows v9.1
    - Linux: DependencyAgentLinux v9.1
    
    VM Insights Benefits:
    - Visual service map showing VM dependencies
    - Network connection metrics and latency
    - Failed connection detection
    - Process-level visibility
    - Application topology mapping
    
    Impact: Enables comprehensive application dependency mapping and performance
    monitoring through VM Insights. Essential for understanding application architecture,
    troubleshooting connectivity issues, and planning migrations or changes.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$False, HelpMessage="Optional resource group name to limit scope")]
    [String]$ResourceGroupName
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all VMs
$successCount = 0
$failureCount = 0
$alreadyInstalledCount = 0
$missingPrerequisiteCount = 0
$notRunningCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Install Dependency Agent Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
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

# Get list of virtual machines based on scope
Write-Output "Discovering virtual machines..."
Try {
    if ($ResourceGroupName) {
        $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
        Write-Output "Found $($VMs.Count) VMs in resource group: $ResourceGroupName"
    }
    else {
        $VMs = Get-AzVM -Status -ErrorAction Stop
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

# Process each VM to install Dependency Agent
Write-Output "Processing VMs for Dependency Agent installation..."
Write-Output "Note: Log Analytics agent (MMA/OMS) must be installed first (required on Linux)"
Write-Output ""

$count = 0
ForEach ($VM in $VMs) {
    $count++
    
    # Show progress every 10 VMs
    if ($count % 10 -eq 0) {
        Write-Output "  Progress: $count/$($VMs.Count) VMs processed..."
    }
    
    # Check if VM is running (powered on)
    # Dependency Agent can only be installed on running VMs
    if ($VM.PowerState -eq 'VM running') {
        
        # Check if Log Analytics agent (MonitoringAgent) is installed
        # This is a prerequisite for Dependency Agent, especially on Linux
        if ($VM.Extensions.Id -imatch 'MonitoringAgent') {
            
            # Check if Dependency Agent is already installed
            if (!($VM.Extensions.Id -imatch 'DependencyAgent')) {
                
                Try {
                    # Determine the correct extension type based on OS
                    Switch ($VM.StorageProfile.OsDisk.OsType) {
                        'Windows' {
                            $ExtensionType = 'DependencyAgentWindows'
                        }
                        'Linux' {
                            $ExtensionType = 'DependencyAgentLinux'
                        }
                        Default {
                            Write-Warning "  ⚠ Skipped $($VM.Name): Unknown OS type"
                            $failureCount++
                            continue
                        }
                    }
                    
                    # Install the Dependency Agent extension
                    Set-AzVMExtension `
                        -ResourceGroupName $VM.ResourceGroupName `
                        -VMName $VM.Name `
                        -Location $VM.Location `
                        -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' `
                        -ExtensionType $ExtensionType `
                        -Name 'DependencyAgent' `
                        -TypeHandlerVersion '9.1' `
                        -ErrorAction Stop | Out-Null
                    
                    Write-Output "  ✓ Installed Dependency Agent on: $($VM.Name) ($($VM.StorageProfile.OsDisk.OsType))"
                    $successCount++
                }
                Catch {
                    Write-Warning "  ✗ Failed to install agent on $($VM.Name): $_"
                    $failureCount++
                }
            } else {
                # Dependency Agent already installed
                $alreadyInstalledCount++
            }
        } else {
            # Log Analytics agent not installed - prerequisite missing
            Write-Warning "  ⚠ Skipped $($VM.Name): Log Analytics agent (MMA/OMS) must be installed first"
            $missingPrerequisiteCount++
        }
    } else {
        # VM is not running - cannot install extensions
        Write-Warning "  ⚠ Skipped $($VM.Name): VM is not running (Power State: $($VM.PowerState))"
        $notRunningCount++
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
Write-Output "Missing Prerequisite (No Log Analytics Agent): $missingPrerequisiteCount"
Write-Output "Not Running: $notRunningCount"
Write-Output "Failed: $failureCount"
Write-Output ""
if ($missingPrerequisiteCount -gt 0) {
    Write-Output "NEXT STEPS:"
    Write-Output "- Install Log Analytics agent (MMA/OMS) on VMs missing the prerequisite"
    Write-Output "- Run this runbook again to install Dependency Agent"
    Write-Output ""
}
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="