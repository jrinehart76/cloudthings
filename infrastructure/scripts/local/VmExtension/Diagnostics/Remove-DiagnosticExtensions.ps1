 <#
    .DESCRIPTION
        Removes Extensions from all customer virtual machines

    .PREREQUISITES
        Account with access to customer Virtual Machines

    .DEPENDENCIES
        Az.Accounts
        Az.Compute

    . PARAMETER CustSPN
        Name of the Azure Automation Connection for the customer

    . PARAMETER CustTenantId
        ID of the customer AAD tenant

    . PARAMETER AutomationAccountName
        Name of the Azure Automation Account

    . PARAMETER AutomationAccountRG
        Name of the Resource Group that contains the Azure Automation Account

    . PARAMETER ResourceGroup
        Resource Group filter string, usually set to "*"
       
    .TODO

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.4.3

    .CHANGELOG

    .VERSION
        1.0.0
#>

param (
    [Parameter(Mandatory=$True)]
    [String]$CustSPN,
    [Parameter(Mandatory=$True)]
    [String]$CustTenantId,
    [Parameter(Mandatory=$True)]
    [String]$AutomationAccountName,
    [Parameter(Mandatory=$True)]
    [String]$AutomationAccountRG,
    [Parameter(Mandatory=$True)]
    [String]$ResourceGroup
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