<#
.SYNOPSIS
    Deploys an Azure Recovery Services Vault for backup and disaster recovery.

.DESCRIPTION
    This script deploys a Recovery Services Vault that provides backup and disaster
    recovery capabilities for the platform. The vault supports:
    
    - Azure VM backup and restore
    - SQL Server in Azure VM backup
    - Azure Files backup
    - On-premises backup via Azure Backup Agent
    - Site Recovery for disaster recovery
    
    The Recovery Services Vault provides:
    - Centralized backup management
    - Long-term retention policies
    - Geo-redundant storage options
    - Compliance and audit capabilities
    - Automated backup scheduling
    
    This is a foundational component for data protection and business continuity.

.PARAMETER resourceGroup
    The resource group where the Recovery Services Vault will be deployed.
    Example: 'rg-platform-prod'

.PARAMETER recoveryVaultName
    The name for the Recovery Services Vault.
    Must be unique within the region.
    Example: 'rsv-platform-prod'

.PARAMETER recoveryVaultLocation
    The Azure region where the vault will be deployed.
    Should match the region of resources being backed up.
    Example: 'eastus', 'westus2'

.EXAMPLE
    .\ta-platform-recoveryvault.ps1 -resourceGroup 'rg-platform-prod' -recoveryVaultName 'rsv-platform-prod' -recoveryVaultLocation 'eastus'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Resource group must exist
    - User must have Contributor role on the resource group
    - ARM template file must exist: ./templates/platform/rsv.json
    
    Vault Configuration:
    - Storage replication type (LRS/GRS) is set in the ARM template
    - Backup policies must be configured post-deployment
    - Soft delete is enabled by default for data protection
    
    Post-Deployment:
    - Configure backup policies for VMs, databases, and files
    - Enable Azure Backup for target resources
    - Set up backup alerts and notifications
    - Configure long-term retention policies
    - Test restore procedures
    
    Impact: Provides centralized backup and disaster recovery capabilities for the platform.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.0.0 - Initial version
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Resource group for the Recovery Services Vault")]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Name for the Recovery Services Vault")]
    [ValidateNotNullOrEmpty()]
    [string]$recoveryVaultName,

    [Parameter(Mandatory=$true, HelpMessage="Azure region for the vault")]
    [ValidateNotNullOrEmpty()]
    [string]$recoveryVaultLocation
)

# Output deployment information
Write-Output "=========================================="
Write-Output "Deploy Recovery Services Vault"
Write-Output "=========================================="
Write-Output "Resource Group: $resourceGroup"
Write-Output "Vault Name: $recoveryVaultName"
Write-Output "Location: $recoveryVaultLocation"
Write-Output ""

Try {
    # Deploy the Recovery Services Vault
    # This vault provides backup and disaster recovery capabilities
    New-AzResourceGroupDeployment `
        -Name "deploy-recovery-vault" `
        -ResourceGroupName $resourceGroup `
        -TemplateFile ./templates/platform/rsv.json `
        -recoveryVaultName $recoveryVaultName `
        -recoveryVaultLocation $recoveryVaultLocation `
        -ErrorAction Stop
    
    Write-Output "✓ Recovery Services Vault deployed successfully"
}
Catch {
    Write-Error "Failed to deploy Recovery Services Vault: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
