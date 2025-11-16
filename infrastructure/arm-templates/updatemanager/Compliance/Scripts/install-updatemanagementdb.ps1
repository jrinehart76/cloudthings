<#
    .DESCRIPTION
        Deploys Update Management Azure SQL Database

    .PREREQUISITES
        Azure Logical SQL Server for Update Management

    .DEPENDENCIES
        Az.Resources

    .PARAMETER databaseName 
        The name of the SQL database
    .PARAMETER sqlServerName
        The name of the SQL server
    .PARAMETER location 
        Location for all resources
    .PARAMETER resourceGroup 
        Name of the resource group for deployment
    .PARAMETER sqlAdministratorLogin 
        The administrator username of the SQL Server
    .PARAMETER sqlAdministratorLoginPassword 
        The administrator password of the SQL Server
    .PARAMETER transparentDataEncryption 
        Enable or disable Transparent Data Encryption (TDE) for the database: Defaults to Enabled
    .PARAMETER deploymentVersion 
        Version of the deployment: two digit month and two digit year, i.e. 0320

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.3.26

    .CHANGELOG

    .VERSION
        1.0.0
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$databaseName,

    [Parameter(Mandatory=$true)]
    [string]$sqlServerName,

    [Parameter(Mandatory=$true)]
    [string]$location,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$sqlAdministratorLogin,

    [Parameter(Mandatory=$true)]
    [securestring]$sqlAdministratorLoginPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$transparentDataEncryption,

    [Parameter(Mandatory=$true)]
    [string]$deploymentVersion
 )

 New-AzResourceGroupDeployment `
    -Name "deploy-MSP-um-sqldb-$databaseName-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile ./UpdateManager/Compliance/Templates/updatecompliance-sqldatabase.json `
    -databaseName $databaseName `
    -sqlServerName $sqlServerName `
    -location $location `
    -sqlAdministratorLogin $sqlAdministratorLogin `
    -sqlAdministratorLoginPassword $sqlAdministratorLoginPassword `
    -transparentDataEncryption $transparentDataEncryption