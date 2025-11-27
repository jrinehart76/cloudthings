<#
.SYNOPSIS
    Enables boot diagnostics for Azure VMs via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook enables boot diagnostics for Azure virtual machines
    that are tagged for platform monitoring. Boot diagnostics provide:
    
    - Serial console output for troubleshooting boot issues
    - Screenshot of VM console for visual diagnostics
    - Critical data for resolving startup failures
    - Support for both Windows and Linux VMs
    
    The runbook:
    - Validates the specified storage account exists
    - Discovers VMs tagged with PLATFORMMonitored=y
    - Checks if boot diagnostics are already enabled
    - Enables boot diagnostics using the specified storage account
    - Skips VMs that already have boot diagnostics enabled
    
    Boot diagnostics are essential for troubleshooting VM startup issues, kernel panics,
    and other boot-related problems that prevent normal VM operation.
    
    Designed for scheduled execution in Azure Automation to maintain compliance.

.PARAMETER StorageAccountName
    The name of the storage account to use for boot diagnostics data.
    The storage account must already exist in the subscription.
    
    Note: Boot diagnostics data is stored as blobs in this storage account.
    
    Example: 'sabootdiagprod'

.PARAMETER ResourceGroupName
    Optional. The name of a specific resource group to target.
    If not specified, the runbook will process all VMs in the subscription.
    
    Only VMs tagged with PLATFORMMonitored=y will be processed.
    
    Example: 'rg-production-vms'

.EXAMPLE
    # Enable boot diagnostics for all tagged VMs in subscription
    .\ta-enable-bootdiag-runbook.ps1 -StorageAccountName 'sabootdiagprod'

.EXAMPLE
    # Enable boot diagnostics for tagged VMs in a specific resource group
    .\ta-enable-bootdiag-runbook.ps1 -StorageAccountName 'sabootdiagprod' -ResourceGroupName 'rg-production-vms'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account with Run As Account (Service Principal) configured
    - Service Principal must have Contributor or Virtual Machine Contributor role
    - Required PowerShell modules in Automation Account:
      * Az.Accounts
      * Az.Compute
      * Az.Storage
    - Storage account must exist in the subscription
    - VMs must be tagged with PLATFORMMonitored=y to be processed
    
    Tagging Requirement:
    - Only VMs with tag PLATFORMMonitored=y are processed
    - This allows selective enablement of boot diagnostics
    - Add this tag to VMs that require boot diagnostics
    
    Impact: Enables critical troubleshooting capabilities for VM boot issues.
    Boot diagnostics are essential for diagnosing startup failures, kernel panics,
    and other issues that prevent remote access to VMs.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - Initial version
#>

Param (
    [Parameter(Mandatory=$True, HelpMessage="Name of the storage account for boot diagnostics")]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$False, HelpMessage="Optional resource group name to limit scope")]
    [string]$ResourceGroupName
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all VMs
$successCount = 0
$failureCount = 0
$alreadyEnabledCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Enable VM Boot Diagnostics Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Storage Account: $StorageAccountName"
if ($ResourceGroupName) {
    Write-Output "Target Resource Group: $ResourceGroupName"
} else {
    Write-Output "Target Scope: All tagged VMs in subscription"
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

# Validate storage account exists
Write-Output "Validating storage account..."
Try {
    $StorageAccount = Get-AzStorageAccount -ErrorAction Stop | Where-Object {$_.StorageAccountName -eq $StorageAccountName}
    
    if ($StorageAccount) {
        Write-Output "Storage Account: $($StorageAccount.StorageAccountName)"
        Write-Output "Resource Group: $($StorageAccount.ResourceGroupName)"
        Write-Output "Location: $($StorageAccount.Location)"
        Write-Output "Blob Endpoint: $($StorageAccount.PrimaryEndpoints.Blob)"
        Write-Output ""
    } else {
        Write-Error "Storage account '$StorageAccountName' not found in subscription."
        Write-Error "Please verify the storage account exists and you have access to it."
        return
    }
}
Catch {
    Write-Error "Failed to validate storage account: $_"
    throw
}

# Get list of VMs tagged for platform monitoring
Write-Output "Discovering virtual machines with PLATFORMMonitored=y tag..."
Try {
    if ($ResourceGroupName) {
        $Machines = Get-AzVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop | 
            Where-Object {$_.Tags["PLATFORMMonitored"] -eq 'y'}
        Write-Output "Found $($Machines.Count) tagged VMs in resource group: $ResourceGroupName"
    }
    else {
        $Machines = Get-AzVM -Status -ErrorAction Stop | 
            Where-Object {$_.Tags["PLATFORMMonitored"] -eq 'y'}
        Write-Output "Found $($Machines.Count) tagged VMs in subscription"
    }
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve VMs: $_"
    throw
}

# Validate VMs were found
if (!($Machines) -or $Machines.Count -eq 0) {
    Write-Output "No VMs found with PLATFORMMonitored=y tag. Exiting."
    Write-Output "Add the tag PLATFORMMonitored=y to VMs that should have boot diagnostics enabled."
    return
}

# Process each VM to enable boot diagnostics
Write-Output "Processing VMs for boot diagnostics..."
$count = 0
ForEach ($Machine in $Machines) {
    $count++
    
    # Show progress every 10 VMs
    if ($count % 10 -eq 0) {
        Write-Output "  Progress: $count/$($Machines.Count) VMs processed..."
    }
    
    # Check if boot diagnostics are already enabled
    if (!$Machine.DiagnosticsProfile.BootDiagnostics.Enabled) {
        Try {
            # Get the VM resource to update properties
            $Resource = Get-AzResource `
                -ResourceName $Machine.Name `
                -ResourceGroupName $Machine.ResourceGroupName `
                -ExpandProperties `
                -ErrorAction Stop
            
            # Enable boot diagnostics
            $Resource.Properties.diagnosticsProfile.bootDiagnostics.enabled = $true
            $Resource.Properties.diagnosticsProfile.BootDiagnostics.storageUri = $StorageAccount.PrimaryEndpoints.Blob
            
            # Apply the configuration
            $Resource | Set-AzResource -Force -ErrorAction Stop | Out-Null
            
            Write-Output "  ✓ Enabled boot diagnostics: $($Machine.Name)"
            $successCount++
        }
        Catch {
            Write-Warning "  ✗ Failed to enable boot diagnostics on $($Machine.Name): $_"
            $failureCount++
        }
    } else {
        # Boot diagnostics already enabled
        $alreadyEnabledCount++
    }
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total VMs Processed: $($Machines.Count)"
Write-Output "Successfully Enabled: $successCount"
Write-Output "Already Enabled: $alreadyEnabledCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="
