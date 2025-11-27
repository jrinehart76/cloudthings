<#
.SYNOPSIS
    Deploys an Azure SQL Server for Update Management compliance infrastructure.

.DESCRIPTION
    This script deploys an Azure SQL Server (logical server) that hosts the Update
    Management compliance database. The server provides:
    
    - Centralized database hosting for compliance data
    - Advanced Data Security (ADS) for threat detection
    - Firewall rules for Azure service access
    - Connection policy configuration (Default, Redirect, Proxy)
    - Foundation for multi-database compliance tracking
    
    The SQL Server is configured with:
    - Administrator authentication
    - Optional Azure service access
    - Advanced Data Security features
    - Configurable connection routing
    
    After deployment, use ta-install-update-database.ps1 to create databases.

.PARAMETER serverName
    The name for the Azure SQL Server (logical server).
    Must be globally unique across Azure.
    Example: 'sql-updatemanagement-prod'

.PARAMETER location
    The Azure region for the SQL Server deployment.
    Example: 'eastus', 'westus2'

.PARAMETER resourceGroup
    The resource group where the SQL Server will be deployed.
    Example: 'rg-updatemanagement-prod'

.PARAMETER administratorLogin
    The administrator username for the SQL Server.
    Cannot be 'admin', 'administrator', 'sa', 'root', etc.
    Example: 'sqladmin'

.PARAMETER administratorLoginPassword
    The administrator password for the SQL Server.
    Must meet complexity requirements:
    - At least 8 characters
    - Contains uppercase, lowercase, numbers, and special characters
    Type: SecureString

.PARAMETER enableADS
    Enable Advanced Data Security for threat detection and vulnerability assessment.
    Requires the deploying user to have Administrator or Owner permissions.
    Default: True

.PARAMETER allowAzureIPs
    Allow Azure services and resources to access this server.
    Required for Hybrid Workers and Azure-based applications.
    Default: False

.PARAMETER connectionType
    SQL Server connection policy type.
    - Default: Uses Azure default policy (Redirect for Azure, Proxy for external)
    - Redirect: Lower latency, direct connection to database node
    - Proxy: All connections routed through Azure SQL gateway
    Valid values: 'Default', 'Redirect', 'Proxy'

.PARAMETER deploymentVersion
    Version identifier for the deployment.
    Format: Two-digit month + two-digit year (MMYY)
    Example: '0125' for January 2025

.EXAMPLE
    $password = ConvertTo-SecureString 'YourComplexPassword123!' -AsPlainText -Force
    .\ta-install-update-sql.ps1 -serverName 'sql-updatemanagement-prod' -location 'eastus' -resourceGroup 'rg-updatemanagement-prod' -administratorLogin 'sqladmin' -administratorLoginPassword $password -enableADS $true -allowAzureIPs $true -connectionType 'Default' -deploymentVersion '0125'

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - User must have Contributor role on the resource group
    - User must have Administrator or Owner role for ADS enablement
    - ARM template file must exist: ./UpdateManager/Compliance/Templates/updatecompliance-sqlserver.json
    
    Server Configuration:
    - Advanced Data Security provides threat detection and vulnerability scanning
    - Azure service access enables Hybrid Workers and Azure Functions
    - Connection type affects latency and routing
    - Firewall rules can be added post-deployment
    
    Post-Deployment:
    - Configure additional firewall rules as needed
    - Enable Azure AD authentication if required
    - Run ta-install-update-database.ps1 to create databases
    - Configure backup retention policies
    - Set up monitoring and alerts
    
    Security Considerations:
    - Use strong administrator passwords
    - Enable Advanced Data Security for production
    - Restrict firewall rules to necessary IPs
    - Consider Azure AD authentication
    - Enable auditing and threat detection
    
    Related Scripts:
    - ta-install-update-database.ps1: Creates databases on this server
    - ta-configure-update-database.ps1: Configures database schema
    - ta-install-update-worker.ps1: Deploys workers that access this server
    
    Impact: Provides the SQL Server foundation for Update Management compliance tracking.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - 2020-03-26 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Name for the Azure SQL Server")]
    [ValidateNotNullOrEmpty()]
    [string]$serverName,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$location,

    [Parameter(Mandatory=$true, HelpMessage="Resource group for deployment")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="SQL Server administrator username")]
    [ValidateNotNullOrEmpty()]
    [string]$administratorLogin,

    [Parameter(Mandatory=$true, HelpMessage="SQL Server administrator password")]
    [ValidateNotNullOrEmpty()]
    [securestring]$administratorLoginPassword,
    
    [Parameter(Mandatory=$true, HelpMessage="Enable Advanced Data Security")]
    [bool]$enableADS,
    
    [Parameter(Mandatory=$true, HelpMessage="Allow Azure services to access server")]
    [bool]$allowAzureIPs,

    [Parameter(Mandatory=$true, HelpMessage="Connection type (Default, Redirect, Proxy)")]
    [ValidateSet("Default", "Redirect", "Proxy")]
    [string]$connectionType,

    [Parameter(Mandatory=$true, HelpMessage="Deployment version (MMYY format)")]
    [ValidateNotNullOrEmpty()]
    [string]$deploymentVersion
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Update Management SQL Server"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Server Name: $serverName"
Write-Output "Location: $location"
Write-Output "Administrator: $administratorLogin"
Write-Output "Advanced Data Security: $enableADS"
Write-Output "Allow Azure IPs: $allowAzureIPs"
Write-Output "Connection Type: $connectionType"
Write-Output "Deployment Version: $deploymentVersion"
Write-Output ""

Try {
    # Deploy the Azure SQL Server
    # This logical server will host Update Management compliance databases
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
        -connectionType $connectionType `
        -ErrorAction Stop
    
    Write-Output "✓ SQL Server deployed successfully"
    Write-Output ""
    Write-Output "Server FQDN: $serverName.database.windows.net"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Configure additional firewall rules if needed"
    Write-Output "2. Run ta-install-update-database.ps1 to create databases"
    Write-Output "3. Enable Azure AD authentication if required"
    Write-Output "4. Configure auditing and threat detection"
}
Catch {
    Write-Error "Failed to deploy SQL Server: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="