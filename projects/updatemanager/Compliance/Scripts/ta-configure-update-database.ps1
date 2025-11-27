<#
.SYNOPSIS
    Configures the database schema for Update Management compliance tracking.

.DESCRIPTION
    This script creates the database table schema required for storing Update Management
    compliance data collected from Windows and Linux VMs. The schema supports:
    
    - VM identification (name, resource group, subscription)
    - Operating system information and compatibility checks
    - Agent status and health monitoring
    - Windows Update configuration details
    - Log Analytics workspace connectivity
    - Diagnostic check results (.NET, WMF, TLS, permissions)
    - Error state tracking
    - Last scan timestamp
    
    The updateManagement table stores diagnostic data collected by:
    - ta-get-update-data-windows.ps1 (Windows VMs)
    - Get-LinuxUMData.py (Linux VMs)
    - ta-get-update-data-runbook.ps1 (orchestration)
    
    This data enables:
    - Compliance reporting and dashboards
    - Proactive issue identification
    - Update readiness assessment
    - Troubleshooting failed update deployments

.PARAMETER SQLInstance
    The Azure SQL Server instance URL.
    Format: <servername>.database.windows.net
    Example: 'sql-updatemanagement-prod.database.windows.net'

.PARAMETER sqlDatabase
    The name of the Azure SQL Database for Update Management data.
    Example: 'sqldb-updatemanagement-prod'

.EXAMPLE
    .\ta-configure-update-database.ps1 -SQLInstance 'sql-updatemanagement-prod.database.windows.net' -sqlDatabase 'sqldb-updatemanagement-prod'
    
    Creates the updateManagement table schema in the specified database.

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure SQL Server must exist
    - Azure SQL Database must exist
    - SqlServer PowerShell module must be installed
    - User must have CREATE TABLE permissions on the database
    - Firewall rules must allow connection from execution location
    
    Table Schema:
    - vmname (PK): Virtual machine name
    - rgname: Resource group name
    - ostype: Operating system type (Windows/Linux)
    - oscheck: OS version compatibility check result
    - agentstatus: MMA/OMS agent status
    - powerstate: VM power state (running/stopped)
    - lastrun: Timestamp of last compliance scan
    - errorstate: Error flag (True/False)
    - dotnetver: .NET Framework version (Windows only)
    - wmfver: Windows Management Framework version (Windows only)
    - agenterrors: Agent error details
    - permissionstatus: Crypto folder permissions check (Windows only)
    - tlsstatus: TLS 1.2 configuration status
    - workspaceid: Log Analytics workspace ID
    - wuenabled: Windows Update enabled status (Windows only)
    - wulocation: Windows Update server location (Windows only)
    - wuoption: Windows Update download option (Windows only)
    - subscription: Azure subscription ID
    
    Post-Configuration:
    - Verify table creation in Azure Portal or SQL Management Studio
    - Grant appropriate permissions to the Hybrid Worker service principal
    - Test data insertion with sample records
    - Configure Power BI dashboard to connect to this database
    
    Related Scripts:
    - ta-install-update-database.ps1: Deploys the Azure SQL Database
    - ta-install-update-sql.ps1: Deploys the Azure SQL Server
    - ta-get-update-data-runbook.ps1: Populates this table with compliance data
    
    Impact: Provides the data foundation for Update Management compliance tracking.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-26 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Azure SQL Server instance URL")]
    [ValidateNotNullOrEmpty()]
    [string]$SQLInstance,

    [Parameter(Mandatory=$true, HelpMessage="Azure SQL Database name")]
    [ValidateNotNullOrEmpty()]
    [string]$sqlDatabase
)

# Output configuration information
Write-Output "=========================================="
Write-Output "Configure Update Management Database Schema"
Write-Output "=========================================="
Write-Output "SQL Server: $SQLInstance"
Write-Output "Database: $sqlDatabase"
Write-Output ""

Try {
    # Import SQL Server module for database operations
    Write-Output "Loading SqlServer module..."
    Import-Module -Name SqlServer -ErrorAction Stop
    Write-Output "✓ SqlServer module loaded"
    
    # Define the table schema
    # This schema supports both Windows and Linux VM diagnostic data
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
    
    # Prompt for SQL credentials
    Write-Output ""
    Write-Output "Please enter the credentials for [$SQLInstance]"
    $sqlCredential = Get-Credential -Message "Enter SQL Server credentials"
    
    if (-not $sqlCredential) {
        throw "Credentials are required to create the database schema"
    }
    
    # Create the table schema
    Write-Output ""
    Write-Output "Creating updateManagement table..."
    Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $query -Credential $sqlCredential -Database $sqlDatabase -ErrorAction Stop
    
    Write-Output "✓ Database schema created successfully"
    Write-Output ""
    Write-Output "Table: updateManagement"
    Write-Output "Primary Key: vmname"
    Write-Output "Columns: 18 (supports Windows and Linux diagnostic data)"
}
Catch {
    Write-Error "[$SQLInstance] - [$sqlDatabase] - Failed to create database schema: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Configuration Complete"
Write-Output "=========================================="