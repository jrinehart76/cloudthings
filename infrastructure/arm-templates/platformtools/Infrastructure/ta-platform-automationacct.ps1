<#
.SYNOPSIS
    Deploys an Azure Automation Account for runbook execution and automation.

.DESCRIPTION
    This script deploys an Azure Automation Account that provides automation
    capabilities for the platform. The Automation Account supports:
    
    - PowerShell and Python runbook execution
    - Scheduled automation tasks
    - Update Management for VM patching
    - Configuration Management (DSC)
    - Hybrid Worker support for on-premises automation
    
    The Automation Account provides:
    - Centralized automation management
    - Credential and certificate storage
    - Integration with Log Analytics
    - Runbook version control
    - Shared resources (variables, connections, modules)
    
    This is a foundational component for platform automation and orchestration.

.PARAMETER automationAccountName
    The name for the Automation Account.
    Must be unique within the region.
    Example: 'aa-platform-prod'

.PARAMETER automationAccountLocation
    The Azure region where the Automation Account will be deployed.
    Example: 'eastus', 'westus2'

.PARAMETER resourceGroup
    The resource group where the Automation Account will be deployed.
    Example: 'rg-platform-prod'

.EXAMPLE
    .\ta-platform-automationacct.ps1 -automationAccountName 'aa-platform-prod' -automationAccountLocation 'eastus' -resourceGroup 'rg-platform-prod'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/platform/automation.json
    
    Post-Deployment:
    - Create a Run As account for Azure resource authentication
    - Import required PowerShell modules
    - Upload runbooks for automation tasks
    - Configure schedules for recurring tasks
    - Link to Log Analytics workspace for runbook logging
    - Set up hybrid workers if on-premises automation is needed
    
    Security Considerations:
    - Run As accounts provide authentication to Azure resources
    - Store sensitive data in Automation credentials/certificates
    - Use managed identities where possible
    - Regularly rotate Run As account certificates
    
    Related Scripts:
    - Runbook scripts in ../automationscripts/ directory
    - ta-platform-loganalytics.ps1: Deploys Log Analytics for runbook logging
    
    Impact: Provides centralized automation capabilities for the entire platform.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Name for the Automation Account")]
    [ValidateNotNullOrEmpty()]
    [string]$automationAccountName,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the Automation Account")]
    [ValidateNotNullOrEmpty()]
    [string]$automationAccountLocation,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Automation Account"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Account Name: $automationAccountName"
Write-Output "Location: $automationAccountLocation"
Write-Output ""

Try {
    # Deploy the Automation Account
    # This account provides runbook execution and automation capabilities
    New-AzResourceGroupDeployment `
        -Name "deploy-automation-account" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/platform/automation.json `
        -automationAccountName $automationAccountName `
        -automationAccountLocation $automationAccountLocation `
        -ErrorAction Stop
    
    Write-Output "✓ Automation Account deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Create a Run As account for Azure authentication"
    Write-Output "2. Import required PowerShell modules"
    Write-Output "3. Upload and configure runbooks"
    Write-Output "4. Link to Log Analytics workspace"
}
Catch {
    Write-Error "Failed to deploy Automation Account: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
