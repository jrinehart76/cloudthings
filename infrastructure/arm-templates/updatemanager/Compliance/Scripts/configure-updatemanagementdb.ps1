<#
    .DESCRIPTION
        Configure database schema for update management database

    .PREREQUISITES
        Azure Logical SQL Server for Update Management
        Azure SQL Database for Update Management Customer Data

    .DEPENDENCIES
        Az.Resources

    .PARAMETER SQLInstance 
        The Azure SQL Server Instance URL
    .PARAMETER sqlDatabase 
        Name of the customer SQL database

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.3.26

    .CHANGELOG

    .VERSION
        1.0.0
#>

param (
    [Parameter(Mandatory=$True)]
    [String]$SQLInstance,

    [Parameter(Mandatory=$True)]
    [String]$sqlDatabase
)

Import-Module -Name SqlServer

$query = "
CREATE TABLE updateManagement (
    vmname varchar(255) NOT NULL PRIMARY KEY,
    rgname varchar(255) NOT NULL,
    ostype varchar(255),
    oscheck varchar(255),
    agentstatus varchar(255),
    powerstate varchar(255),
    lastrun varchar(255),
    errorstate varchar(255),
    dotnetver varchar(255),
    wmfver varchar(255),
    agenterrors varchar(255),
    permissionstatus varchar(255),
    tlsstatus varchar(255),
    workspaceid varchar(255),
    wuenabled varchar(255),
    wulocation varchar(255),
    wuoption varchar(255),
    subscription varchar(255)
);
"

Write-Output "Please enter the crendentials for [$($SQLInstance)]"
$sqlCredential = Get-Credential

try {
    Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $query -Credential $sqlCredential -Database $sqlDatabase
} catch {
    Write-Error "[$($SQLInstance)] - [$($sqlDatabase)] - Unable to create database schema"
}

Write-Output "[$($SQLInstance)] - [$($sqlDatabase)] - Successfully created database schema"