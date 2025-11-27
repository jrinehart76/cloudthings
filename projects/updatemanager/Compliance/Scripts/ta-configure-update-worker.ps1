<#
.SYNOPSIS
    Configures an Azure Automation Hybrid Runbook Worker for Update Management.

.DESCRIPTION
    This script configures a Windows VM as an Azure Automation Hybrid Runbook Worker,
    enabling it to execute runbooks locally for Update Management compliance scanning.
    
    The script performs the following configuration steps:
    1. Locates the latest Microsoft Monitoring Agent (MMA) version
    2. Imports the Hybrid Registration PowerShell module
    3. Registers the VM as a Hybrid Runbook Worker in the specified group
    4. Installs required PowerShell modules (Az, SqlServer)
    5. Configures Orchestrator.Sandbox to support Az.Storage commands
    
    Hybrid Runbook Workers enable:
    - Local execution of runbooks without Azure connectivity requirements
    - Scanning of VMs across multiple subscriptions
    - Compliance data collection and database updates
    - Reduced network latency for VM diagnostics
    
    This worker is specifically configured for Update Management compliance scanning,
    with the necessary modules and configurations to execute ta-get-update-data-runbook.ps1.

.PARAMETER groupName
    The name of the Hybrid Worker Group.
    If the group doesn't exist, it will be created automatically.
    Example: 'UpdateManagement-Workers'

.PARAMETER aaEndpoint
    The Azure Automation Account endpoint URL.
    Format: https://<guid>.<region>.agentsvc.azure-automation.net/accounts/<guid>
    This can be found in the Automation Account under Keys.

.PARAMETER aaKey
    The Azure Automation Account Primary or Secondary access key.
    This authenticates the worker registration.
    Found in the Automation Account under Keys.

.EXAMPLE
    .\ta-configure-update-worker.ps1 -groupName 'UpdateManagement-Workers' -aaEndpoint 'https://12345678-1234-1234-1234-123456789012.eus2.agentsvc.azure-automation.net/accounts/12345678-1234-1234-1234-123456789012' -aaKey 'your-automation-account-key'

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Windows Server 2012 R2 or higher
    - Microsoft Monitoring Agent (MMA) must be installed
    - MMA must be connected to a Log Analytics workspace
    - Azure Automation Account must exist
    - VM must have internet connectivity for module installation
    - Script must be run with Administrator privileges
    
    Post-Configuration:
    - Verify worker registration in Automation Account > Hybrid Worker Groups
    - Test runbook execution on the worker
    - Ensure SQL Server module is available for database operations
    - Verify Az modules are functional
    
    Installed Modules:
    - NuGet (2.8.5.208): Package provider for PowerShell Gallery
    - Az: Azure PowerShell modules for Azure resource management
    - SqlServer: SQL Server management and query execution
    
    Configuration Changes:
    - Orchestrator.Sandbox.exe.config: Modified to support Az.Storage long paths
    - Hybrid Worker registration: Added to specified group
    
    Related Scripts:
    - ta-install-update-worker.ps1: Deploys the worker VM infrastructure
    - ta-get-update-data-runbook.ps1: Runbook executed by this worker
    
    Impact: Enables local runbook execution for Update Management compliance scanning.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-30 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Name of the Hybrid Worker Group")]
    [ValidateNotNullOrEmpty()]
    [string]$groupName,

    [Parameter(Mandatory=$true, HelpMessage="Azure Automation Account endpoint URL")]
    [ValidateNotNullOrEmpty()]
    [string]$aaEndpoint,

    [Parameter(Mandatory=$true, HelpMessage="Azure Automation Account access key")]
    [ValidateNotNullOrEmpty()]
    [string]$aaKey
)

# Output configuration information
Write-Output "=========================================="
Write-Output "Configure Hybrid Runbook Worker"
Write-Output "=========================================="
Write-Output "Worker Group: $groupName"
Write-Output ""

Try {
    # Get the folder name of the latest agent version
    # The MMA agent stores Azure Automation components in versioned folders
    Write-Output "Locating Microsoft Monitoring Agent installation..."
    $baseFolder = "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation"
    
    if (-not (Test-Path $baseFolder)) {
        throw "Microsoft Monitoring Agent not found. Please install MMA before running this script."
    }
    
    $version = Get-ChildItem -Path $baseFolder | Sort-Object -Property Name -Descending | Select-Object -First 1 | Select-Object Name -ExpandProperty Name
    Write-Output "✓ Found MMA version: $version"
    
    # Register as Hybrid Worker
    # This adds the VM to the specified worker group in the Automation Account
    Write-Output ""
    Write-Output "Registering Hybrid Runbook Worker..."
    $hybridRegPath = "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation\$version\HybridRegistration"
    Set-Location $hybridRegPath
    Import-Module .\HybridRegistration.psd1
    Add-HybridRunbookWorker -GroupName $groupName -EndPoint $aaEndpoint -Token $aaKey
    Write-Output "✓ Hybrid Worker registered to group: $groupName"
    
    # Install required PowerShell modules
    # NuGet provider is required for PowerShell Gallery access
    Write-Output ""
    Write-Output "Installing PowerShell modules..."
    Write-Output "Installing NuGet package provider..."
    Install-PackageProvider -Name "Nuget" -RequiredVersion "2.8.5.208" -Force | Out-Null
    Write-Output "✓ NuGet provider installed"
    
    Write-Output "Installing Az and SqlServer modules (this may take several minutes)..."
    Install-Module Az,SqlServer -Force | Out-Null
    Write-Output "✓ Az and SqlServer modules installed"
    
    # Configure Orchestrator Sandbox for Az.Storage compatibility
    # This resolves path handling issues with Az.Storage cmdlets
    # See: https://github.com/Azure/azure-powershell/issues/8531
    Write-Output ""
    Write-Output "Configuring Orchestrator Sandbox for Az.Storage compatibility..."
    $strOrchestratorSandboxDirectory = (Get-ChildItem -Path $baseFolder -Filter 'Orchestrator.Sandbox.exe' -Recurse).Directory.FullName
    $strOrchestratorSandboxConfigName = 'Orchestrator.Sandbox.exe.config'
    $fullPath = Join-Path $strOrchestratorSandboxDirectory $strOrchestratorSandboxConfigName
    
    $objCustomXML = '<configuration><runtime><AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=false" /></runtime></configuration>'
    Out-File -FilePath $fullPath -InputObject $objCustomXML -Force
    Write-Output "✓ Orchestrator Sandbox configured"
    
    Write-Output ""
    Write-Output "✓ Hybrid Runbook Worker configuration complete"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Verify worker appears in Automation Account > Hybrid Worker Groups"
    Write-Output "2. Test runbook execution on this worker"
    Write-Output "3. Configure runbook schedules for Update Management scanning"
}
Catch {
    Write-Error "Failed to configure Hybrid Runbook Worker: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Configuration Complete"
Write-Output "=========================================="