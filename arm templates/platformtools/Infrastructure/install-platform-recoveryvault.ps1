<#
    .DESCRIPTION
        Deploys Recovery Services Vault for use in Azure Backup        

    .PREREQUISITES
        Management Resource Group

    .TODO
        
    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$recoveryVaultName,

    [Parameter(Mandatory=$true)]
    [string]$recoveryVaultLocation
 )

##Declare variables **commented out to allow for dynamic input**
<#
$resourceGroup = "10m-prod-mgmt-01"
$recoveryVaultName = "rsv-prod-01"
$recoveryVaultLocation = "eastus2"
#>

##Deploy recovery services vault
New-AzResourceGroupDeployment `
    -Name "deploy-recovery-vault" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/platform/rsv.json `
    -recoveryVaultName $recoveryVaultName `
    -recoveryVaultLocation $recoveryVaultLocation
