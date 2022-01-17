<#
    .DESCRIPTION
        Deploys Update Management Azure SQL Server

    .PREREQUISITES
        None

    .DEPENDENCIES
        Az.Resources

    .PARAMETER serverName 
        The name of the SQL logical server
    .PARAMETER location 
        Location for all resources
    .PARAMETER resourceGroup 
        Name of the resource group for deployment
    .PARAMETER administratorLogin 
        The administrator username of the SQL logical server
    .PARAMETER administratorLoginPassword 
        The administrator password of the SQL logical server
    .PARAMETER enableADS 
        Enable Advanced Data Security, the user deploying the template must have an administrator or owner permissions: Defaults to True
    .PARAMETER allowAzureIPs 
        Allow Azure services to access server: Defaults to False
    .PARAMETER connectionType 
        SQL logical server connection type: Default, Redirect, or Proxy
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
    [string]$serverName,

    [Parameter(Mandatory=$true)]
    [string]$location,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$administratorLogin,

    [Parameter(Mandatory=$true)]
    [securestring]$administratorLoginPassword,
    
    [Parameter(Mandatory=$true)]
    [bool]$enableADS,
    
    [Parameter(Mandatory=$true)]
    [bool]$allowAzureIPs,

    [Parameter(Mandatory=$true)]
    [string]$connectionType,

    [Parameter(Mandatory=$true)]
    [string]$deploymentVersion
 )

New-AzResourceGroupDeployment `
    -Name "deploy-platform-sql-$deploymentVersion" `
    -ResourceGroupName $resourceGroup `
    -TemplateFile "./UpdateManager/Compliance/Templates/updatecompliance-sqlserver.json" `
    -serverName $serverName `
    -location $location `
    -administratorLogin $administratorLogin `
    -administratorLoginPassword $administratorLoginPassword `
    -enableADS $enableADS `
    -allowAzureIPs $allowAzureIPs `
    -connectionType $connectionType