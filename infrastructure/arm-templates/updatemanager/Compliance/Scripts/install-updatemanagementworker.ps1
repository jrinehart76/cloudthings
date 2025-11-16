<#
    .DESCRIPTION
        Deploys Update Management Azure Automation Runbook Worker

    .PREREQUISITES
        None

    .DEPENDENCIES
        Az.Resources

    .PARAMETER count 
        The number of workers to deploy
    .PARAMETER adminUsername 
        Username of the Virtual Machine
    .PARAMETER adminPassword 
        Password of the Virtual Machine
    .PARAMETER resourceGroup 
        Name of the resource group for deployment
    .PARAMETER deploymentVersion 
        Version of the deployment: two digit month and two digit year, i.e. 0320

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.3.27

    .CHANGELOG

    .VERSION
        1.0.0
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$count,

    [Parameter(Mandatory=$true)]
    [string]$adminUsername,

    [Parameter(Mandatory=$true)]
    [securestring]$adminPassword,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$deploymentVersion
 )

 New-AzResourceGroupDeployment `
    -Name "deploy-MSP-um-hybridWorker-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./UpdateManager/Compliance/Templates/updatecompliance-hybridworker.json `
    -count $count `
    -adminUsername $adminUsername `
    -adminPassword $adminPassword
