<#
.SYNOPSIS
    Enables Azure VM backup protection via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook enables backup protection for Azure virtual machines
    using an existing Recovery Services vault. It automatically:
    
    - Discovers all VMs in the subscription or a specific resource group
    - Validates VMs are in the same region as the Recovery Services vault
    - Checks if backup protection is already enabled
    - Enables backup with the default backup policy if not already protected
    - Skips VMs in different regions to prevent configuration errors
    
    The runbook uses the DefaultPolicy from the Recovery Services vault, which typically
    includes daily backups with 30-day retention. This ensures consistent backup coverage
    across all virtual machines in the environment.
    
    Designed for scheduled execution in Azure Automation to maintain backup compliance.

.PARAMETER rsvName
    The name of the Recovery Services vault to use for backup protection.
    The vault must already exist and be in the same region as the target VMs.
    
    Example: 'rsv-prod-eastus'

.PARAMETER rgName
    Optional. The name of a specific resource group to target.
    If not specified, the runbook will process all VMs in the subscription.
    
    Example: 'rg-production-vms'

.EXAMPLE
    # Enable backup for all VMs in subscription using specified vault
    .\ta-enable-backup-runbook.ps1 -rsvName 'rsv-prod-eastus'

.EXAMPLE
    # Enable backup for VMs in a specific resource group
    .\ta-enable-backup-runbook.ps1 -rsvName 'rsv-prod-eastus' -rgName 'rg-production-vms'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account with Run As Account (Service Principal) configured
    - Service Principal must have Contributor or Backup Contributor role
    - Required PowerShell modules in Automation Account:
      * Az.Accounts
      * Az.Compute
      * Az.RecoveryServices
    - Recovery Services vault must exist in the target region
    - DefaultPolicy must exist in the Recovery Services vault
    
    Regional Requirements:
    - VMs must be in the same Azure region as the Recovery Services vault
    - Cross-region backup is not supported by Azure Backup
    
    Impact: Ensures all virtual machines have backup protection enabled, meeting
    compliance requirements and providing disaster recovery capabilities. Prevents
    data loss from accidental deletion, corruption, or ransomware attacks.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - 2019-07-02 - Initial version
#>

param (
    [Parameter(Mandatory = $True, HelpMessage = "Name of the Recovery Services vault")]
    [ValidateNotNullOrEmpty()]
    [string]$rsvName,

    [Parameter(Mandatory = $False, HelpMessage = "Optional resource group name to limit scope")]
    [string]$rgName
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all VMs
$successCount = 0
$failureCount = 0
$alreadyProtectedCount = 0
$regionMismatchCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Enable VM Backup Protection Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Recovery Services Vault: $rsvName"
if ($rgName) {
    Write-Output "Target Resource Group: $rgName"
} else {
    Write-Output "Target Scope: All VMs in subscription"
}
Write-Output ""

# Connect to Azure using Automation Account Run As Connection
Write-Output "Connecting to Azure..."
$ConnectionName = 'AzureRunAsConnection'

Try {
    # Get the automation connection asset
    $AutomationConnection = Get-AutomationConnection -Name $ConnectionName
    
    # Connect to Azure with the service principal
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal `
        -ErrorAction Stop
    
    # Get subscription context
    $context = Get-AzContext
    Write-Output "Connected to Azure"
    Write-Output "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
    Write-Output "Service Principal: $($AutomationConnection.ApplicationId)"
    Write-Output ""
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection '$ConnectionName' not found. Ensure the Automation Account has a Run As Account configured."
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
    else {
        Write-Error "Failed to connect to Azure: $_"
        throw $_.Exception
    }
}

# Get list of virtual machines based on scope
Write-Output "Discovering virtual machines..."
Try {
    if ($rgName) {
        $VMs = Get-AzVM -ResourceGroupName $rgName -ErrorAction Stop
        Write-Output "Found $($VMs.Count) VMs in resource group: $rgName"
    }
    else {
        $VMs = Get-AzVM -ErrorAction Stop
        Write-Output "Found $($VMs.Count) VMs in subscription"
    }
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve VMs: $_"
    throw
}

# Validate VMs were found
if (!($VMs) -or $VMs.Count -eq 0) {
    Write-Output "No VMs found in the specified scope. Exiting."
    return
}

# Get Recovery Services vault and set context
Write-Output "Configuring Recovery Services vault context..."
Try {
    $Vault = Get-AzRecoveryServicesVault -Name $rsvName -ErrorAction Stop
    Write-Output "Vault: $($Vault.Name)"
    Write-Output "Vault Location: $($Vault.Location)"
    Write-Output "Vault Resource Group: $($Vault.ResourceGroupName)"
    
    # Set the vault context for all subsequent backup operations
    Set-AzRecoveryServicesVaultContext -Vault $Vault -WarningAction SilentlyContinue -ErrorAction Stop
    
    # Get the default backup policy
    $DefaultBackupPolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy" -ErrorAction Stop
    Write-Output "Backup Policy: $($DefaultBackupPolicy.Name)"
    Write-Output ""
}
Catch {
    Write-Error "Failed to configure vault context: $_"
    throw
}

# Get list of already protected VMs (backup containers)
Write-Output "Checking existing backup protection..."
Try {
    $BackupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType 'AzureVM' -Status 'Registered' -ErrorAction Stop
    Write-Output "Found $($BackupContainers.Count) VMs already protected"
    Write-Output ""
}
Catch {
    Write-Warning "Could not retrieve backup containers: $_"
    $BackupContainers = @()
}

# Process each virtual machine to enable backup protection
Write-Output "Processing VMs for backup protection..."
$count = 0
ForEach ($VM in $VMs) {
    $count++
    
    # Show progress every 10 VMs
    if ($count % 10 -eq 0) {
        Write-Output "  Progress: $count/$($VMs.Count) VMs processed..."
    }
    
    # Check if VM is in the same region as the vault
    if ($VM.Location -eq $Vault.Location) {
        # Check if VM is already protected
        $isProtected = $BackupContainers | Where-Object { $_.FriendlyName -eq $VM.Name }
        
        if (!$isProtected) {
            Try {
                # Enable backup protection with default policy
                Enable-AzRecoveryServicesBackupProtection `
                    -Policy $DefaultBackupPolicy `
                    -Name $VM.Name `
                    -ResourceGroupName $VM.ResourceGroupName `
                    -ErrorAction Stop | Out-Null
                
                Write-Output "  ✓ Enabled backup: $($VM.Name) (RG: $($VM.ResourceGroupName))"
                $successCount++
            }
            Catch {
                Write-Warning "  ✗ Failed to enable backup on $($VM.Name): $_"
                $failureCount++
            }
        }
        else {
            # VM already has backup protection enabled
            $alreadyProtectedCount++
        }
    }
    else {
        # VM is in a different region than the vault
        Write-Warning "  ⚠ Skipped $($VM.Name): Region mismatch (VM: $($VM.Location), Vault: $($Vault.Location))"
        $regionMismatchCount++
    }
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total VMs Processed: $($VMs.Count)"
Write-Output "Successfully Enabled: $successCount"
Write-Output "Already Protected: $alreadyProtectedCount"
Write-Output "Region Mismatch: $regionMismatchCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="
