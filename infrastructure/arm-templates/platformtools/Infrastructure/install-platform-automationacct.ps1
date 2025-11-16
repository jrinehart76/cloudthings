<#
    .DESCRIPTION
        Deploys the default Automation Account resource

    .PREREQUISITES
        None

    .TODO
        Create 'run-as' account on deployment

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$automationAccountName,

    [Parameter(Mandatory=$true)]
    [string]$automationAccountLocation,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup
 )

##Declare variables **commented out to allow for dynamic input**
<#
$automationAccountName = "aa-prod-01"
$automationAccountLocation = "eastus2"
$resourceGroup = "MSP-prod-mgmt-01"
#>

##Deploy automation account
New-AzResourceGroupDeployment `
    -Name "deploy-automation-account" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./templates/platform/automation.json `
    -automationAccountName $automationAccountName `
    -automationAccountLocation $automationAccountLocation
