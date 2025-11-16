<#
    .DESCRIPTION
        Deploys the diagnostic storage account used for platform diagnostic and boot diagnostics        

    .PREREQUISITES
        None        

    .TODO
        
    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$diagStorageLocation,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

##Declare variables **commented out to allow for dynamic input**
<#
$diagStorageLocation = "eastus"
$resourceGroup = "MSP-prod-mgmt-01"
#>

$randStr = -join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})

##Deploy diagnostic storage account
New-AzResourceGroupDeployment `
    -Name "deploy-diagnostic-storage-${randStr}" `
    -TemplateFile ./templates/platform/diagstorage.json `
    -ResourceGroupName $resourceGroup `
    -diagStorageLocation $diagStorageLocation