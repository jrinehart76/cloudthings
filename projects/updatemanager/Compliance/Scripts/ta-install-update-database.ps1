<#
.SYNOPSIS
    Deploys an Azure SQL Database for Update Management compliance data.

.DESCRIPTION
    This script deploys an Azure SQL Database that stores Update Management compliance
    data collected from Windows and Linux VMs across the environment. The database:
    
    - Stores diagnostic check results from VM scans
    - Tracks Update Management readiness and configuration
    - Enables compliance reporting via Power BI dashboards
    - Supports multi-subscription VM scanning
    - Provides historical compliance data
    
    The database is configured with:
    - Transparent Data Encryption (TDE) for data at rest protection
    - Appropriate performance tier for compliance workloads
    - Firewall rules for Hybrid Worker access
    - Backup and retention policies
    
    After deployment, use ta-configure-update-database.ps1 to create the table schema.

.PARAMETER databaseName
    The name for the Azure SQL Database.
    Example: 'sqldb-updatemanagement-prod'

.PARAMETER sqlServerName
    The name of the existing Azure SQL Server.
    The database will be created on this server.
    Example: 'sql-updatemanagement-prod'

.PARAMETER location
    The Azure region for the database deployment.
    Should match the SQL Server location.
    Example: 'eastus', 'westus2'

.PARAMETER resourceGroup
    The resource group where the database will be deployed.
    Should match the SQL Server resource group.
    Example: 'rg-updatemanagement-prod'

.PARAMETER sqlAdministratorLogin
    The administrator username for the SQL Server.
    Used for initial database configuration.
    Example: 'sqladmin'

.PARAMETER sqlAdministratorLoginPassword
    The administrator password for the SQL Server.
    Must meet Azure SQL password complexity requirements.
    Type: SecureString

.PARAMETER transparentDataEncryption
    Enable or disable Transparent Data Encryption (TDE) for the database.
    TDE encrypts data at rest for compliance and security.
    Valid values: 'Enabled', 'Disabled'
    Default: 'Enabled'

.PARAMETER deploymentVersion
    Version identifier for the deployment.
    Format: Two-digit month + two-digit year (MMYY)
    Example: '0125' for January 2025

.EXAMPLE
    $password = ConvertTo-SecureString 'YourComplexPassword123!' -AsPlainText -Force
    .\ta-install-update-database.ps1 -databaseName 'sqldb-updatemanagement-prod' -sqlServerName 'sql-updatemanagement-prod' -location 'eastus' -resourceGroup 'rg-updatemanagement-prod' -sqlAdministratorLogin 'sqladmin' -sqlAdministratorLoginPassword $password -transparentDataEncryption 'Enabled' -deploymentVersion '0125'

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure SQL Server must exist
    - Resource group must exist
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./UpdateManager/Compliance/Templates/updatecompliance-sqldatabase.json
    
    Database Configuration:
    - Service tier and performance level defined in ARM template
    - TDE enabled by default for security compliance
    - Backup retention configured per Azure SQL defaults
    - Geo-replication can be configured post-deployment
    
    Post-Deployment:
    - Run ta-configure-update-database.ps1 to create table schema
    - Configure firewall rules for Hybrid Worker access
    - Grant permissions to service principals
    - Configure backup retention policies if needed
    - Set up Power BI connection for reporting
    
    Related Scripts:
    - ta-install-update-sql.ps1: Deploys the Azure SQL Server
    - ta-configure-update-database.ps1: Creates the database schema
    - ta-get-update-data-runbook.ps1: Populates the database with compliance data
    
    Impact: Provides centralized storage for Update Management compliance data.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-26 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Name for the Azure SQL Database")]
    [ValidateNotNullOrEmpty()]
    [string]$databaseName,

    [Parameter(Mandatory=$true, HelpMessage="Name of the existing Azure SQL Server")]
    [ValidateNotNullOrEmpty()]
    [string]$sqlServerName,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$location,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="SQL Server administrator username")]
    [ValidateNotNullOrEmpty()]
    [string]$sqlAdministratorLogin,

    [Parameter(Mandatory=$true, HelpMessage="SQL Server administrator password")]
    [ValidateNotNullOrEmpty()]
    [securestring]$sqlAdministratorLoginPassword,
    
    [Parameter(Mandatory=$true, HelpMessage="Enable Transparent Data Encryption (Enabled/Disabled)")]
    [ValidateSet("Enabled", "Disabled")]
    [string]$transparentDataEncryption,

    [Parameter(Mandatory=$true, HelpMessage="Deployment version (MMYY format)")]
    [ValidateNotNullOrEmpty()]
    [string]$deploymentVersion
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Update Management SQL Database"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "SQL Server: $sqlServerName"
Write-Output "Database: $databaseName"
Write-Output "Location: $location"
Write-Output "TDE: $transparentDataEncryption"
Write-Output "Deployment Version: $deploymentVersion"
Write-Output ""

Try {
    # Deploy the Azure SQL Database
    # This database will store Update Management compliance data
    New-AzResourceGroupDeployment `
        -Name "deploy-PLATFORM-um-sqldb-$databaseName-$deploymentVersion" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./UpdateManager/Compliance/Templates/updatecompliance-sqldatabase.json `
        -databaseName $databaseName `
        -sqlServerName $sqlServerName `
        -location $location `
        -sqlAdministratorLogin $sqlAdministratorLogin `
        -sqlAdministratorLoginPassword $sqlAdministratorLoginPassword `
        -transparentDataEncryption $transparentDataEncryption `
        -ErrorAction Stop
    
    Write-Output "✓ SQL Database deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Run ta-configure-update-database.ps1 to create table schema"
    Write-Output "2. Configure firewall rules for Hybrid Worker access"
    Write-Output "3. Grant permissions to service principals"
    Write-Output "4. Test database connectivity"
}
Catch {
    Write-Error "Failed to deploy SQL Database: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="