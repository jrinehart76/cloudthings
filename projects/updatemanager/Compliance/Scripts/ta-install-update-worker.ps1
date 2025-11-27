<#
.SYNOPSIS
    Deploys Azure Automation Hybrid Runbook Worker VMs for Update Management.

.DESCRIPTION
    This script deploys one or more Windows VMs configured as Azure Automation
    Hybrid Runbook Workers for Update Management compliance scanning. The workers:
    
    - Execute runbooks locally without Azure connectivity requirements
    - Scan VMs across multiple subscriptions and tenants
    - Collect compliance data and update SQL databases
    - Provide scalability for large VM estates
    - Enable parallel processing of compliance scans
    
    The deployment creates:
    - Windows Server VMs with appropriate sizing
    - Network interfaces and security groups
    - Managed disks for OS and data
    - Public IPs (if configured in template)
    - VM extensions for monitoring and management
    
    After deployment, use ta-configure-update-worker.ps1 to register the VMs
    as Hybrid Runbook Workers in the Automation Account.

.PARAMETER count
    The number of Hybrid Worker VMs to deploy.
    Multiple workers enable parallel scanning and load distribution.
    Example: '2' for two worker VMs

.PARAMETER adminUsername
    The administrator username for the Virtual Machines.
    Cannot be 'admin', 'administrator', 'root', etc.
    Example: 'vmadmin'

.PARAMETER adminPassword
    The administrator password for the Virtual Machines.
    Must meet Windows complexity requirements:
    - At least 12 characters
    - Contains uppercase, lowercase, numbers, and special characters
    Type: SecureString

.PARAMETER resourceGroup
    The resource group where the worker VMs will be deployed.
    Example: 'rg-updatemanagement-prod'

.PARAMETER deploymentVersion
    Version identifier for the deployment.
    Format: Two-digit month + two-digit year (MMYY)
    Example: '0125' for January 2025

.EXAMPLE
    $password = ConvertTo-SecureString 'YourComplexPassword123!' -AsPlainText -Force
    .\ta-install-update-worker.ps1 -count '2' -adminUsername 'vmadmin' -adminPassword $password -resourceGroup 'rg-updatemanagement-prod' -deploymentVersion '0125'
    
    Deploys 2 Hybrid Worker VMs for Update Management scanning.

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - Virtual network and subnet must exist (or be created by template)
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./UpdateManager/Compliance/Templates/updatecompliance-hybridworker.json
    
    VM Configuration:
    - OS: Windows Server (version specified in template)
    - Size: Defined in ARM template (typically Standard_D2s_v3 or similar)
    - Disks: Managed disks with appropriate performance tier
    - Extensions: May include monitoring, antimalware, etc.
    
    Post-Deployment:
    - Install Microsoft Monitoring Agent (MMA) on each worker
    - Connect MMA to Log Analytics workspace
    - Run ta-configure-update-worker.ps1 to register as Hybrid Workers
    - Install required PowerShell modules (Az, SqlServer)
    - Test runbook execution
    - Configure worker group assignments
    
    Scaling Considerations:
    - Deploy multiple workers for large VM estates (1000+ VMs)
    - Each worker can scan approximately 50-100 VMs concurrently
    - Consider regional placement for multi-region environments
    - Monitor worker CPU and memory during scans
    
    Related Scripts:
    - ta-configure-update-worker.ps1: Configures VMs as Hybrid Workers
    - ta-install-update-runbooks.ps1: Deploys runbooks for workers to execute
    - ta-get-update-data-runbook.ps1: Main runbook executed by workers
    
    Impact: Provides the compute infrastructure for Update Management compliance scanning.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-27 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Number of Hybrid Worker VMs to deploy")]
    [ValidateRange(1, 10)]
    [string]$count,

    [Parameter(Mandatory=$true, HelpMessage="Administrator username for the VMs")]
    [ValidateNotNullOrEmpty()]
    [string]$adminUsername,

    [Parameter(Mandatory=$true, HelpMessage="Administrator password for the VMs")]
    [ValidateNotNullOrEmpty()]
    [securestring]$adminPassword,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Deployment version (MMYY format)")]
    [ValidateNotNullOrEmpty()]
    [string]$deploymentVersion
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Hybrid Runbook Worker VMs"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Worker Count: $count"
Write-Output "Administrator: $adminUsername"
Write-Output "Deployment Version: $deploymentVersion"
Write-Output ""

Try {
    # Deploy the Hybrid Worker VMs
    # These VMs will execute Update Management compliance scanning runbooks
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-um-hybridWorker-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./UpdateManager/Compliance/Templates/updatecompliance-hybridworker.json `
        -count $count `
        -adminUsername $adminUsername `
        -adminPassword $adminPassword `
        -ErrorAction Stop
    
    Write-Output "✓ Hybrid Worker VMs deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Install Microsoft Monitoring Agent (MMA) on each worker"
    Write-Output "2. Connect MMA to Log Analytics workspace"
    Write-Output "3. Run ta-configure-update-worker.ps1 on each VM to register as Hybrid Worker"
    Write-Output "4. Verify workers appear in Automation Account > Hybrid Worker Groups"
    Write-Output "5. Test runbook execution on the workers"
}
Catch {
    Write-Error "Failed to deploy Hybrid Worker VMs: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
