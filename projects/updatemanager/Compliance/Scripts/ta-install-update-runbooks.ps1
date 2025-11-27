<#
.SYNOPSIS
    Deploys Update Management compliance scanning runbooks to Azure Automation.

.DESCRIPTION
    This script deploys the runbooks and supporting scripts required for Update
    Management compliance scanning. It performs the following operations:
    
    1. Creates an Azure Storage Account for script storage
    2. Creates a storage container for Update Management scripts
    3. Uploads diagnostic scripts (Windows and Linux) to blob storage
    4. Creates the compliance scanner runbook in Azure Automation
    5. Imports and publishes the runbook for execution
    
    The deployed runbook (UpdateManagement_ComplianceScanner) orchestrates:
    - Multi-subscription VM scanning
    - Execution of diagnostic scripts on VMs
    - Collection of compliance data
    - Storage of results in Azure SQL Database
    
    Supporting scripts uploaded to storage:
    - Get-LinuxUMData.py: Linux VM diagnostic script
    - Get-WindowsUMData.ps1: Windows VM diagnostic script
    
    These scripts are downloaded by Hybrid Workers during runbook execution.

.PARAMETER automationAccountName
    The name of the Azure Automation Account where runbooks will be deployed.
    Example: 'aa-updatemanagement-prod'

.PARAMETER saResourceGroup
    The resource group for the storage account.
    Storage account will be created here if it doesn't exist.
    Example: 'rg-updatemanagement-prod'

.PARAMETER aaResourceGroup
    The resource group containing the Azure Automation Account.
    Example: 'rg-updatemanagement-prod'

.EXAMPLE
    .\ta-install-update-runbooks.ps1 -automationAccountName 'aa-updatemanagement-prod' -saResourceGroup 'rg-updatemanagement-prod' -aaResourceGroup 'rg-updatemanagement-prod'

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account must exist
    - Resource groups must exist
    - User must have Contributor role on resource groups
    - Script files must exist in ./UpdateManager/Compliance/Scripts/:
      * Get-LinuxUMData.py
      * Get-WindowsUMData.ps1
      * xm_Get-UpdateManagementData.ps1 (main runbook)
    
    Storage Account Configuration:
    - Name: platformautoscripts (hardcoded)
    - SKU: Standard_LRS
    - Container: updatemanagement
    - Purpose: Stores diagnostic scripts for Hybrid Worker download
    
    Runbook Configuration:
    - Name: UpdateManagement_ComplianceScanner
    - Type: PowerShell
    - Execution: Hybrid Runbook Worker
    - Purpose: Orchestrates VM compliance scanning
    
    Post-Deployment:
    - Configure runbook schedules for regular scanning
    - Set up Automation credentials for SQL access
    - Configure Automation connections for customer subscriptions
    - Test runbook execution on Hybrid Workers
    - Monitor runbook job history
    
    Related Scripts:
    - ta-configure-update-worker.ps1: Configures Hybrid Workers to execute this runbook
    - ta-get-update-data-runbook.ps1: The main runbook being deployed
    - Get-WindowsUMData.ps1: Windows diagnostic script
    - Get-LinuxUMData.py: Linux diagnostic script
    
    Impact: Enables automated Update Management compliance scanning across the environment.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-04-02 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Name of the Azure Automation Account")]
    [ValidateNotNullOrEmpty()]
    [string]$automationAccountName,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for the storage account")]
    [ValidateNotNullOrEmpty()]
    [string]$saResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for the Automation Account")]
    [ValidateNotNullOrEmpty()]
    [string]$aaResourceGroup
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Update Management Runbooks"
Write-Output "=========================================="
Write-Output "Automation Account: $automationAccountName"
Write-Output "Automation RG: $aaResourceGroup"
Write-Output "Storage RG: $saResourceGroup"
Write-Output ""

Try {
    # Get resource group location for storage account
    $rg = Get-AzResourceGroup -Name $saResourceGroup -ErrorAction Stop
    
    # Create storage account for diagnostic scripts
    # Hybrid Workers will download scripts from this storage
    Write-Output "Creating storage account for diagnostic scripts..."
    $storageAccount = New-AzStorageAccount `
        -Name "platformautoscripts" `
        -ResourceGroupName $saResourceGroup `
        -Location $rg.location `
        -SkuName "Standard_LRS" `
        -ErrorAction SilentlyContinue
    
    if ($storageAccount) {
        Write-Output "✓ Storage account created: platformautoscripts"
    } else {
        Write-Output "✓ Storage account already exists: platformautoscripts"
    }
    
    # Get storage account context
    $keys = Get-AzStorageAccountKey -Name "platformautoscripts" -ResourceGroupName $saResourceGroup
    $ctx = New-AzStorageContext -StorageAccountName "platformautoscripts" -StorageAccountKey $keys.Value[0]
    
    # Create storage container
    Write-Output "Creating storage container..."
    $container = New-AzStorageContainer -Name "updatemanagement" -Context $ctx -ErrorAction SilentlyContinue
    if ($container) {
        Write-Output "✓ Container created: updatemanagement"
    } else {
        Write-Output "✓ Container already exists: updatemanagement"
    }
    
    # Upload diagnostic scripts to blob storage
    Write-Output ""
    Write-Output "Uploading diagnostic scripts to blob storage..."
    Set-AzStorageBlobContent `
        -File './UpdateManager/Compliance/Scripts/Get-LinuxUMData.py' `
        -Container 'updatemanagement' `
        -Blob 'Get-LinuxUMData.py' `
        -Context $ctx `
        -Force | Out-Null
    Write-Output "✓ Uploaded: Get-LinuxUMData.py"
    
    Set-AzStorageBlobContent `
        -File './UpdateManager/Compliance/Scripts/Get-WindowsUMData.ps1' `
        -Container 'updatemanagement' `
        -Blob 'Get-WindowsUMData.ps1' `
        -Context $ctx `
        -Force | Out-Null
    Write-Output "✓ Uploaded: Get-WindowsUMData.ps1"
    
    # Create and publish runbook in Azure Automation
    Write-Output ""
    Write-Output "Creating runbook in Azure Automation..."
    $runbook = New-AzAutomationRunbook `
        -AutomationAccountName $automationAccountName `
        -Name 'UpdateManagement_ComplianceScanner' `
        -ResourceGroupName $aaResourceGroup `
        -Type PowerShell `
        -ErrorAction SilentlyContinue
    
    if ($runbook) {
        Write-Output "✓ Runbook created: UpdateManagement_ComplianceScanner"
    } else {
        Write-Output "✓ Runbook already exists: UpdateManagement_ComplianceScanner"
    }
    
    # Import runbook content
    Write-Output "Importing runbook content..."
    Import-AzAutomationRunbook `
        -Name 'UpdateManagement_ComplianceScanner' `
        -Path "./UpdateManager/Compliance/Scripts/xm_Get-UpdateManagementData.ps1" `
        -Type PowerShell `
        -ResourceGroupName $aaResourceGroup `
        -AutomationAccountName $automationAccountName `
        -Force | Out-Null
    Write-Output "✓ Runbook content imported"
    
    # Publish runbook
    Write-Output "Publishing runbook..."
    Publish-AzAutomationRunbook `
        -AutomationAccountName $automationAccountName `
        -ResourceGroupName $aaResourceGroup `
        -Name 'UpdateManagement_ComplianceScanner' | Out-Null
    Write-Output "✓ Runbook published"
    
    Write-Output ""
    Write-Output "✓ All runbooks and scripts deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Configure runbook schedules for regular scanning"
    Write-Output "2. Set up Automation credentials for SQL database access"
    Write-Output "3. Configure Automation connections for customer subscriptions"
    Write-Output "4. Test runbook execution on Hybrid Workers"
}
Catch {
    Write-Error "Failed to deploy runbooks: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
