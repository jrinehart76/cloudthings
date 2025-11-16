<#
    .DESCRIPTION
        Deploys Update Management Runbooks

    .PREREQUISITES
        Azure Automation Account

    .DEPENDENCIES
        Az.Resources

    .PARAMETER automationAccountName 
        The name of the Azure Automation Account
    .PARAMETER saResourceGroup 
        Name of the resource group for storage account
    .PARAMETER aaResourceGroup 
        Name of the resource group for automation account

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.4.2

    .CHANGELOG

    .VERSION
        1.0.0
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$automationAccountName,

    [Parameter(Mandatory=$true)]
    [string]$saResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$aaResourceGroup
 )

$rg = Get-AzResourceGroup -Name $saResourceGroup

# Create script storage
New-AzStorageAccount -Name "mspplatformautoscripts" -ResourceGroupName $saResourceGroup -Location $rg.location -SkuName "Standard_LRS" -ErrorAction SilentlyContinue
$keys = Get-AzStorageAccountKey -Name "mspplatformautoscripts" -ResourceGroupName $saResourceGroup
$ctx = New-AzStorageContext -StorageAccountName "mspplatformautoscripts" -StorageAccountKey $keys.Value[0]
New-AzStorageContainer -Name "updatemanagement" -Context $ctx -ErrorAction SilentlyContinue

# Upload scripts to storage account
Set-AzStorageBlobContent -File './UpdateManager/Compliance/Scripts/Get-LinuxUMData.py' -Container 'updatemanagement' -Blob 'Get-LinuxUMData.py' -Context $ctx -Force
Set-AzStorageBlobContent -File './UpdateManager/Compliance/Scripts/Get-WindowsUMData.ps1' -Container 'updatemanagement' -Blob 'Get-WindowsUMData.ps1' -Context $ctx -Force

# Create Runbook(s) in Azure Automation Account
New-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name 'UpdateManagement_ComplianceScanner' -ResourceGroupName $resourceGroup -Type PowerShell -ErrorAction SilentlyContinue
Import-AzAutomationRunbook -Name 'UpdateManagement_ComplianceScanner' -Path "./UpdateManager/Compliance/Scripts/xm_Get-UpdateManagementData.ps1" -Type PowerShell -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName –Force
Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroup -Name 'UpdateManagement_ComplianceScanner'
