<#
.SYNOPSIS
    Remove VM diagnostics extensions from customer VMs via Azure Automation

.DESCRIPTION
    This Azure Automation runbook removes VM diagnostics extensions from all
    customer VMs across subscriptions. Used for:
    - Cleanup during decommissioning
    - Migration to new diagnostics configuration
    - Removing misconfigured extensions
    - Preparation for reconfiguration
    
    The script:
    - Authenticates using Azure Automation service principals
    - Processes multiple subscriptions in parallel
    - Filters VMs by resource group pattern
    - Excludes AKS and Databricks VMs automatically
    - Removes only non-MSP managed diagnostics extensions
    - Uses parallel job execution for performance
    
    Real-world impact: Enables automated cleanup of diagnostics extensions
    across large multi-subscription environments.

.PARAMETER CustSPN
    Name of the Azure Automation Connection for the customer service principal

.PARAMETER CustTenantId
    Azure AD tenant ID for the customer

.PARAMETER AutomationAccountName
    Name of the Azure Automation Account running this runbook

.PARAMETER AutomationAccountRG
    Resource group containing the Automation Account

.PARAMETER ResourceGroup
    Resource group filter pattern (e.g., "*" for all, "rg-prod-*" for production)

.EXAMPLE
    # Run as Azure Automation runbook
    .\ta-remove-vm-diagnostics.ps1 -CustSPN "CustomerSPN" -CustTenantId "tenant-guid" -AutomationAccountName "aa-prod" -AutomationAccountRG "rg-automation" -ResourceGroup "*"

.NOTES
    Author: Jason Rinehart aka Technical Anxiety (enhanced from dnite original)
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    Original Author: dnite
    
    Prerequisites:
    - Azure Automation Account with RunAs account
    - Customer service principal connection configured
    - Az.Accounts and Az.Compute modules in Automation Account
    - Virtual Machine Contributor role on VMs
    
    Impact: Removes diagnostics extensions for cleanup or reconfiguration.
    Use with caution - this will stop diagnostics data collection.
    
    Note: This is designed to run as an Azure Automation runbook.
    Requires proper service principal authentication setup.

.VERSION
    2.0.0 - Enhanced documentation and error handling
    1.0.0 - Initial release by dnite

.CHANGELOG
    2.0.0 - Added comprehensive documentation, improved logging
    1.0.0 - Initial version by dnite (2020.4.3)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Customer service principal connection name")]
    [ValidateNotNullOrEmpty()]
    [string]$CustSPN,
    
    [Parameter(Mandatory=$true, HelpMessage="Customer Azure AD tenant ID")]
    [ValidateNotNullOrEmpty()]
    [string]$CustTenantId,
    
    [Parameter(Mandatory=$true, HelpMessage="Automation Account name")]
    [ValidateNotNullOrEmpty()]
    [string]$AutomationAccountName,
    
    [Parameter(Mandatory=$true, HelpMessage="Automation Account resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$AutomationAccountRG,
    
    [Parameter(Mandatory=$true, HelpMessage="Resource group filter pattern")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup
)

function Get-TimeStamp {
  return "{0:MM/dd/yy} {0:HH:mm:ss}" -f (Get-Date)
}

$scriptblock = {
param (
    [Parameter(Mandatory=$True)]
    [Object]$sub,

    [Parameter(Mandatory=$True)]
    [String]$ResourceGroup
)

    Set-AzContext -SubscriptionObject $sub

    $winExtension = 'Microsoft.Insights.VMDiagnosticsSettings'
    $nixExtension = 'LinuxDiagnostic'
    $vms = @()
    $vms = Get-AzVm -Status -ResourceGroupName $ResourceGroup | `
            Where-Object { ($_.Name -notlike "aks-*") -and ($_.Name -notlike "k8*") -and ($_.StorageProfile.ImageReference.Offer -ne "Databricks") } | `
            Select-Object -Property Name,ResourceGroupName,powerstate,@{Name='osType'; Expression={$_.storageProfile.osDisk.osType}}

    Write-Output "Found [$($vms.count)] VMs that match the Resource Group Name Filter - [$($ResourceGroup)]"
    Write-Output "VM Processing List: $($vms.Name)"

    ## Loop Through VMs ##
    foreach ($vm in $vms) {
        Write-Output "[$($vm.Name)] - Begin Processing"

        if ($vm.powerstate -like "*running") {
            ## Get configuration details from the virtual machine ##
            Write-Output "[$($vm.Name)] - Getting current extension configuration status"

            $VMex = Get-AzVMExtension `
                        -ResourceGroupName $vm.ResourceGroupName `
                        -VMName $vm.Name `
                        -ErrorAction "SilentlyContinue"

            foreach ($ex in $VMex) {
                if (($ex.Publisher -like "Microsoft.Azure.Diagnostics") -and ($ex.Etag -notlike '{"ManagedBy":"ManagedServiceProvider"}')) {
                    Write-Output "[$($vm.Name)] Found [$($ex.Name)]" 
                    Write-Output "[$($vm.Name)] Removing [$($ex.Name)]"
                    $error.clear()
                    try {
                        Remove-AzVMDiagnosticsExtension `
                            -ResourceGroupName $vm.ResourceGroupName `
                            -VMName $vm.Name `
                            -Name $ex.Name `
                            -NoWait `
                            -ErrorAction "SilentlyContinue" `
                            | Out-Null
                    } catch {
                        Write-Error "[$($vm.Name)] - Unable to remove [$($ex.Name)]. May require manual removal."
                    }
                    if (!$error) {
                        Write-Output "[$($vm.Name)] - Successfully removed [$($ex.Name)]"
                    }
                }
                elseif (($ex.Publisher -like "Microsoft.Azure.Diagnostics") -and ($ex.Etag -like '{"ManagedBy":"ManagedServiceProvider"}')){
                    Write-Output "[$($vm.Name)] - Found [$($ex.Name)] - Already correctly installed" 
                }
                else {
                    Write-Output "[$($vm.Name)] - No diagnostics extension currently installed"
                }
            }
        }
        else {
            Write-Output "[$($vm.Name)] - Not running or not compatible with VM diagnostics" 
        }
    }
}

Disable-AzContextAutosave –Scope Process | Out-Null

#Connect as automation SPN goes here
$RunAsConnectionName = 'AzureRunAsConnection'
$SPConnectionName = $CustSPN
$AutomationConnection = Get-AutomationConnection -Name $RunAsConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$startTime = Get-TimeStamp

$SPAutomationConnection = Get-AzAutomationConnection -AutomationAccountName $AutomationAccountName -Name $SPConnectionName -ResourceGroupName $AutomationAccountRG

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $SPAutomationConnection.FieldDefinitionValues.CertificateThumbprint `
        -ApplicationId $SPAutomationConnection.FieldDefinitionValues.ApplicationId `
        -Tenant $TenantId `
        -ServicePrincipal
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$throttle = 20
$Jobs = @()
$Subscriptions = Get-AzSubscription

foreach ($sub in $Subscriptions) {

  Get-AzSubscription -SubscriptionName $sub.Name | Set-AzContext | Out-Null

  Write-Output "Starting scan of Subscription - [$($sub.Name)]"
  
  $RunningJobs = $Jobs | Where-Object {$_.State -eq 'Running'}

  if ($RunningJobs.Count -ge $throttle) {
    Write-Output "Max job queue of [$($Throttle)] reached. Please wait while existing jobs are processed..."
    $RunningJobs | Wait-Job -Any | Out-Null
  }

  $Jobs += Start-Job -ScriptBlock $scriptblock -ArgumentList $sub, $ResourceGroup
}

if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs | Receive-Job

$endTime = Get-TimeStamp

Write-Output "Script Start Time - [$($startTime)]"
Write-Output "Script End Time - [$($endTime)]"


<#
USAGE NOTES:

1. Azure Automation Runbook:
   This script is designed to run as an Azure Automation runbook.
   It requires:
   - Azure Automation Account with RunAs account configured
   - Customer service principal connection configured in Automation Account
   - Az.Accounts and Az.Compute modules imported
   - Proper RBAC permissions on target VMs

2. Service Principal Setup:
   - RunAs Account: Built-in Automation Account identity
   - Customer SPN: Custom service principal for customer access
   - Both must have Virtual Machine Contributor role
   - Certificate-based authentication required

3. What Gets Removed:
   - VM diagnostics extensions (Microsoft.Azure.Diagnostics)
   - Only extensions NOT managed by MSP (checked via Etag)
   - Windows: Microsoft.Insights.VMDiagnosticsSettings
   - Linux: LinuxDiagnostic
   
4. What Gets Preserved:
   - Extensions with Etag: {"ManagedBy":"ManagedServiceProvider"}
   - AKS node VMs (automatically excluded)
   - Databricks VMs (automatically excluded)
   - VMs that are not running

5. Parallel Processing:
   - Processes subscriptions in parallel (throttle: 20)
   - Significantly faster for multi-subscription environments
   - Each subscription processed as separate job
   - Results aggregated at completion

6. Common Use Cases:
   - Decommissioning old diagnostics configuration
   - Migration to new storage account
   - Cleanup before reconfiguration
   - Removing misconfigured extensions

EXPECTED RESULTS:
- Diagnostics extensions removed from matching VMs
- MSP-managed extensions preserved
- AKS and Databricks VMs skipped
- Detailed logging of all actions

REAL-WORLD IMPACT:
Automated diagnostics cleanup is essential for:
- Large-scale migrations
- Multi-subscription management
- Standardization initiatives
- Decommissioning projects

Without automation:
- Manual removal per VM (time-consuming)
- Risk of removing wrong extensions
- Inconsistent results
- Extended maintenance windows

With automation:
- Consistent removal across subscriptions
- Parallel processing for speed
- Automatic exclusion of managed resources
- Detailed audit trail

TROUBLESHOOTING:
Common Issues:
- "Connection not found" - Verify service principal connections
- "Permission denied" - Check RBAC roles on VMs
- "Extension not found" - VM may not have diagnostics
- Job timeout - Reduce throttle or batch subscriptions

Verification:
- Check runbook job output in Automation Account
- Verify extensions removed: Get-AzVMExtension
- Review VM diagnostics in Azure Portal
- Check for any failed removals in logs

NEXT STEPS:
1. Verify extensions removed successfully
2. Reconfigure diagnostics if needed
3. Update documentation
4. Test monitoring still functional
5. Review runbook execution logs
#>
