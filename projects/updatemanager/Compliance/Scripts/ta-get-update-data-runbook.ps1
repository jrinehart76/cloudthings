<#
.SYNOPSIS
    Azure Automation runbook for Update Management compliance scanning across multiple subscriptions.

.DESCRIPTION
    This runbook orchestrates Update Management compliance scanning across an entire
    Azure environment. It performs the following operations:
    
    1. Authenticates to Azure using Automation Run As account
    2. Connects to customer subscriptions using service principal
    3. Discovers VMs across all subscriptions (filtered by resource group)
    4. Executes diagnostic scripts on Windows and Linux VMs via Invoke-AzVMRunCommand
    5. Collects compliance data (OS version, agent status, Windows Update config, etc.)
    6. Stores results in Azure SQL Database for reporting
    7. Processes multiple subscriptions in parallel with throttling
    
    The runbook handles:
    - Multi-subscription scanning with parallel processing
    - Both Windows and Linux VM diagnostics
    - VM power state detection (skips stopped VMs)
    - Error handling and timeout management
    - SQL database INSERT and UPDATE operations
    - Job queue management with throttling
    
    Diagnostic data collected includes:
    - Operating system compatibility
    - .NET Framework and WMF versions (Windows)
    - TLS 1.2 configuration
    - Microsoft Monitoring Agent status
    - Log Analytics workspace connectivity
    - Windows Update configuration
    - Agent errors and permissions
    
    This runbook is designed to run on Hybrid Runbook Workers with access to:
    - Customer Azure subscriptions
    - Azure SQL Database
    - Storage account with diagnostic scripts

.PARAMETER sqlInstance
    The Azure SQL Server instance URL.
    Format: <servername>.database.windows.net
    Example: 'sql-updatemanagement-prod.database.windows.net'

.PARAMETER sqlDatabase
    The Azure SQL Database name for storing compliance data.
    Example: 'sqldb-updatemanagement-prod'

.PARAMETER sqlCredentialName
    The name of the Azure Automation PSCredential asset containing SQL credentials.
    This credential must have INSERT and UPDATE permissions on the database.
    Example: 'SQL-UpdateManagement-Credential'

.PARAMETER CustomerConnectionName
    The name of the Azure Automation Connection asset for the customer service principal.
    This connection provides access to customer Azure subscriptions.
    Example: 'AzureConnection-Customer1'

.PARAMETER CustomerTenantId
    The Azure AD Tenant ID for the customer being scanned.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER ResourceGroupFilter
    Resource group name filter for VM discovery.
    Use '*' to scan all resource groups, or specify a pattern.
    Example: '*', 'rg-prod-*', 'rg-customer1-*'

.PARAMETER Throttle
    Maximum number of subscriptions to process simultaneously.
    Controls parallel job execution to prevent resource exhaustion.
    Recommended: 20 for most environments
    Example: 20

.EXAMPLE
    # This runbook is typically executed via Azure Automation schedule
    # Parameters are configured in the schedule or passed at runtime
    
    Start-AzAutomationRunbook -AutomationAccountName 'aa-updatemanagement-prod' -Name 'UpdateManagement_ComplianceScanner' -ResourceGroupName 'rg-automation-prod' -Parameters @{
        sqlInstance = 'sql-updatemanagement-prod.database.windows.net'
        sqlDatabase = 'sqldb-updatemanagement-prod'
        sqlCredentialName = 'SQL-UpdateManagement-Credential'
        CustomerConnectionName = 'AzureConnection-Customer1'
        CustomerTenantId = '12345678-1234-1234-1234-123456789012'
        ResourceGroupFilter = '*'
        Throttle = 20
    }

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account with Hybrid Runbook Worker
    - Hybrid Worker must have required PowerShell modules (Az, SqlServer)
    - Azure Automation Run As account configured
    - Customer service principal connection configured
    - SQL Server credential asset configured
    - Storage account with diagnostic scripts (Get-WindowsUMData.ps1, Get-LinuxUMData.py)
    - Azure SQL Database with updateManagement table schema
    
    Execution Environment:
    - Runs on: Hybrid Runbook Worker
    - Execution time: Varies by VM count (typically 1-4 hours for 1000+ VMs)
    - Timeout: 300 seconds per VM diagnostic execution
    - Parallel processing: Controlled by Throttle parameter
    
    Storage Account Configuration:
    - Resource Group: rg-oms-dev (hardcoded)
    - Storage Account: platformautomationsa (hardcoded)
    - Container: updatemanagement
    - Scripts: Get-WindowsUMData.ps1, Get-LinuxUMData.py
    
    SQL Database Operations:
    - INSERT: New VMs not in database
    - UPDATE: Existing VMs with updated compliance data
    - Query: Check for existing VM records
    
    Error Handling:
    - VM extension errors: Flagged in errorstate column
    - Timeout errors: Logged and flagged
    - Stopped VMs: Recorded with power state
    - Unsupported OS: Logged as error
    
    Performance Considerations:
    - Throttle parameter controls subscription parallelism
    - VM diagnostics run with 300-second timeout
    - Jobs are queued and processed as workers become available
    - Large environments may require multiple Hybrid Workers
    
    Related Scripts:
    - ta-install-update-runbooks.ps1: Deploys this runbook
    - ta-configure-update-worker.ps1: Configures Hybrid Workers
    - Get-WindowsUMData.ps1: Windows VM diagnostic script
    - Get-LinuxUMData.py: Linux VM diagnostic script
    
    Impact: Provides automated, scheduled Update Management compliance scanning and reporting.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and parameter validation
    1.1.0 - 2020-04-14 - Added multi-subscription support (dnite)
    1.0.0 - Initial version (dnite)
#>

param (
    [Parameter(Mandatory=$True)]
    [String]$sqlInstance,

    [Parameter(Mandatory=$True)]
    [String]$sqlDatabase,

    [Parameter(Mandatory=$True)]
    [string]$sqlCredentialName,

    [Parameter(Mandatory=$True)]
    [String]$CustomerConnectionName,

    [Parameter(Mandatory=$True)]
    [String]$CustomerTenantId,

    [Parameter(Mandatory=$True)]
    [String]$ResourceGroupFilter,

    [Parameter(Mandatory=$True)]
    [Int]$Throttle
)

# Script storage account details
$StorageAccountRG = 'rg-oms-dev'
$StorageAccount = 'platformautomationsa'

function Get-TimeStamp {
  return "{0:MM/dd/yy} {0:HH:mm:ss}" -f (Get-Date)
}

$scriptblock = {
    param (
        [Parameter(Mandatory=$True)]
        [String]$SQLInstance,

        [Parameter(Mandatory=$True)]
        [PSCredential]$sqlCredential,

        [Parameter(Mandatory=$True)]
        [String]$sqlDatabase,

        [Parameter(Mandatory=$True)]
        [String]$sub,

        [Parameter(Mandatory=$True)]
        [String]$tenant,

        [Parameter(Mandatory=$True)]
        [String]$ResourceGroupFilter,

        [Parameter(Mandatory=$True)]
        [String]$SPConnectionName,

        [Parameter(Mandatory=$True)]
        [Object]$AutomationConnection
    )

    function Get-TimeStamp {
        return "{0:MM/dd/yy} {0:HH:mm:ss}" -f (Get-Date)
    }

    function Get-SQLData {
        param(
            [string]$sqlInstance,
            [string]$sqlDatabase,
            [System.Management.Automation.PSCredential]$sqlCredential,
            [string]$vmName
        )
        $query = "SELECT * FROM [dbo].[updateManagement] WHERE [vmname] = `'" + $vmName + "`'"
        
        Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $query -Credential $sqlCredential -Database $sqlDatabase
        Write-Output "[$($vm.Name)] - SQL Read Query - [$($query)]"
    }

    function Write-NewDataSQL {
        param(
            [string]$sqlInstance,
            [string]$sqlDatabase,
            [System.Management.Automation.PSCredential]$sqlCredential,
            $vm,
            $updateData,
            $workspaceid,
            $err,
            $subscription
        )

        $timestamp = Get-TimeStamp

        if ($err -eq 'True') {
            $query = "
            INSERT INTO [dbo].[updateManagement] 
                        ([powerstate],
                        [ostype],
                        [errorstate],
                        [lastrun],
                        [rgname],
                        [vmname],
                        [subscription])
            VALUES (`'" + $vm.powerstate  + "`',
                    `'" + $vm.osType + "`',
                    `'" + $err + "`',
                    `'" + $timestamp + "`',
                    `'" + $vm.ResourceGroupName + "`',
                    `'" + $vm.Name + "`',
                    `'" + $subscription + "`');
            "
        } else {
            if ($vm.powerstate -notlike "*running") {
            $query = "
            INSERT INTO [dbo].[updateManagement]
                        ([powerstate],
                        [ostype],
                        [errorstate],
                        [lastrun],
                        [rgname],
                        [vmname],
                        [subscription])
            VALUES (`'notRunning`',
                    `'" + $vm.osType + "`',
                    `'" + $err + "`',
                    `'" + $timestamp + "`',
                    `'" + $vm.ResourceGroupName + "`',
                    `'" + $vm.Name + "`',
                    `'" + $subscription + "`');
            "
            } else {
            if ($vm.osType -like "windows") {
                $query = "
                INSERT INTO [dbo].[updateManagement]
                            ([powerstate],
                            [errorstate],
                            [lastrun],
                            [oscheck],
                            [ostype],
                            [dotnetver], 
                            [wmfver],
                            [agentstatus],  
                            [agenterrors],
                            [permissionstatus], 
                            [tlsstatus],
                            [workspaceid], 
                            [wuenabled],
                            [wuoption],
                            [wulocation],
                            [rgname],
                            [vmname],
                            [subscription]) 
                VALUES (`'" + $vm.powerstate  + "`',
                        `'" + $err + "`',
                        `'" + $timestamp + "`',
                        `'" + $updateData[0].CheckResult + "`', 
                        `'Windows`', 
                        `'" + $updateData[1].CheckResult + "`', 
                        `'" + $updateData[2].CheckResult + "`', 
                        `'" + $updateData[3].CheckResult + "`', 
                        `'" + $updateData[4].CheckResult + "`', 
                        `'" + $updateData[5].CheckResult + "`', 
                        `'" + $updateData[6].CheckResult + "`', 
                        `'" + $updateData[7].CheckResult + "`', 
                        `'" + $updateData[8].CheckResult + "`', 
                        `'" + $updateData[9].CheckResult + "`', 
                        `'" + $updateData[10].CheckResult + "`',
                        `'" + $vm.ResourceGroupName + "`',
                        `'" + $vm.Name + "`',
                        `'" + $subscription + "`');
                "
            } elseif ($vm.osType -like "linux") {
                $query = "
                INSERT INTO [dbo].[updateManagement]
                            ([powerstate],
                            [errorstate],
                            [lastrun],
                            [vmname], 
                            [oscheck],
                            [ostype],
                            [agentstatus],
                            [rgname], 
                            [workspaceid],
                            [subscription]) 
                VALUES (`'" + $vm.powerstate  + "`',
                        `'" + $err + "`',
                        `'" + $timestamp + "`',
                        `'" + $vm.Name + "`', 
                        `'" + $updateData[0].checkresult + "`',
                        `'Linux`', 
                        `'" + $updateData[2].checkresult + "`',
                        `'" + $vm.ResourceGroupName + "`',
                        `'" + $workspaceid + "`',
                        `'" + $subscription + "`');
                "
            } else {
                Write-Error "[$($vm.Name)] - Unsupported Operating System"
            }
            }
        }

        Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $query -Credential $sqlCredential -Database $sqlDatabase
        Write-Output "[$($vm.Name)] - SQL NewData Query - [$($query)]"
    }

    function Write-UpdateDataSQL {
        param(
            [string]$sqlInstance,
            [string]$sqlDatabase,
            [System.Management.Automation.PSCredential]$sqlCredential,
            $vm,
            $updateData,
            $workspaceid,
            $err,
            $subscription
        )

        $timestamp = Get-TimeStamp

        if ($err -eq 'True') {
            $query = "
            UPDATE [dbo].[updateManagement] 
            SET [powerstate] = `'" + $vm.powerstate  + "`',
                [ostype] = `'" + $vm.osType + "`',
                [errorstate] = `'" + $err + "`',
                [lastrun] = `'" + $timestamp + "`',
                [rgname] = `'" + $vm.ResourceGroupName + "`',
                [subscription] = `'" + $subscription + "`'
            WHERE [vmname] = `'" + $vm.Name + "`';
            "
        } else {
            if ($vm.powerstate -notlike "*running") {
            $query = "
            UPDATE [dbo].[updateManagement]
            SET [powerstate] = `'notRunning`',
                [ostype] = `'" + $vm.osType + "`',
                [errorstate] = `'" + $err + "`',
                [lastrun] = `'" + $timestamp + "`',
                [rgname] = `'" + $vm.ResourceGroupName + "`',
                [subscription] = `'" + $subscription + "`'
            WHERE [vmname] = `'" + $vm.Name + "`';
            "
            } else {
                if ($vm.osType -like "windows") {
                    $query = "
                    UPDATE [dbo].[updateManagement]
                    SET [oscheck] = `'" + $updateData[0].CheckResult + "`',
                        [powerstate] = `'" + $vm.powerstate  + "`',
                        [errorstate] = `'" + $err + "`',
                        [lastrun] = `'" + $timestamp + "`',
                        [ostype] =  `'Windows`',
                        [dotnetver] = `'" + $updateData[1].CheckResult + "`',
                        [wmfver] = `'" + $updateData[2].CheckResult + "`',
                        [agentstatus] = `'" + $updateData[3].CheckResult + "`',
                        [agenterrors] = `'" + $updateData[4].CheckResult + "`',
                        [permissionstatus] = `'" + $updateData[5].CheckResult + "`', 
                        [tlsstatus] = `'" + $updateData[6].CheckResult + "`', 
                        [workspaceid] = `'" + $updateData[7].CheckResult + "`',
                        [wuenabled] = `'" + $updateData[8].CheckResult + "`',
                        [wuoption] = `'" + $updateData[9].CheckResult + "`',
                        [wulocation] = `'" + $updateData[10].CheckResult + "`',
                        [rgname] = `'" + $vm.ResourceGroupName + "`',
                        [subscription] = `'" + $subscription + "`'
                    WHERE [vmname] = `'" + $vm.Name + "`';
                    "
                } elseif ($vm.osType -like "linux") {
                    $query = "
                    UPDATE [dbo].[updateManagement]
                    SET [oscheck] = `'" + $updateData[0].checkresult + "`',
                        [powerstate] = `'" + $vm.powerstate  + "`',
                        [errorstate] = `'" + $err + "`',
                        [lastrun] = `'" + $timestamp + "`',
                        [ostype] =  `'Linux`',
                        [agentstatus] = `'" + $updateData[2].checkresult + "`',
                        [workspaceid] = `'" + $workspaceid + "`',
                        [rgname] = `'" + $vm.ResourceGroupName + "`',
                        [subscription] = `'" + $subscription + "`'
                    WHERE [vmname] = `'" + $vm.Name + "`';
                    "
                } else {
                    Write-Error "[$($vm.Name)] - Unsupported Operating System"
                }
            }
        }
        
        Invoke-Sqlcmd -ServerInstance $sqlInstance -Query $query -Credential $sqlCredential -Database $sqlDatabase
        Write-Output "[$($vm.Name)] - SQL Update Query - [$($query)]"
    }

    Import-AzContext -Path C:\Scripts\context.json

    Import-Module -Name SqlServer

    Set-AzContext -Subscription $sub -Tenant $tenant

    $winScript = "Get-WindowsUMData.ps1"
    $nixScript = "Get-LinuxUMData.py"
    $vms = @()
    $vms = Get-AzVm -Status -ResourceGroupName $ResourceGroupFilter | `
            Where-Object { ($_.Name -notlike "aks-*") -and ($_.StorageProfile.ImageReference.Offer -ne "Databricks") } | `
            Select-Object -Property Name,ResourceGroupName,powerstate,@{Name='osType'; Expression={$_.storageProfile.osDisk.osType}}

    Write-Output "Found [$($vms.count)] VMs that match the Resource Group Name Filter - [$($ResourceGroupFilter)]"

    ## Loop Through VMs ##
    foreach ($vm in $vms) {
        $err = 'False'
        $workspaceid = $sqlRead = $updateData = $query = $vm_job = $null
        Write-Output "[$($vm.Name)] - Begin Processing"

        ## Check for existing SQL entries
        $sqlRead = Get-SQLData -sqlInstance $SQLInstance -sqlDatabase $sqlDatabase -sqlCredential $sqlCredential $vm.Name

        ## Get configuration details from the virtual machine ##
        Write-Output "[$($vm.Name)] - Getting current configuration status"

        $monextension = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -vmname $vm.Name | Where-Object {$_.Publisher -eq "Microsoft.EnterpriseCloud.Monitoring"}
        if (($monextension.ProvisioningState -ne "Succeeded") -or ($vm.ProvisioningState -eq "Updating")) {
        Write-Output "[$($vm.Name)] - VM extensions in error state"
        $err = 'True'
        $updateData = 'agentError'
        $workspaceid = 'null'
        } else {
            if (($vm.osType -eq "Windows") -and ($vm.powerstate -like "*running")) {
                $timeout=''
                try {
                    $vm_job = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunPowerShellScript' -ScriptPath "C:\Scripts\$winScript" -AsJob
                    Wait-Job -Id $vm_job.Id -Timeout 300
                } catch {
                    Write-Output 
                }
                if ($(Get-Job -Id $vm_job.Id).State -eq "Running") {
                #Stop-Job -Id $vm_job.Id   ## Stopping the job can lead powershell to crash
                Write-Output "[$($vm.Name)] - Timed Out while getting VM configuration"
                $err = 'True'
                $updateData = 'TimedOut'
                $workspaceid = 'null'
                } elseif ($(Get-Job -Id $vm_job.Id).State -eq "Completed") {
                $outputJson = ''
                if ($outputJson = Get-Job -Id $vm_job.Id | Receive-Job -Keep | Select-Object -First 1) {
                    Write-Output "[$($vm.Name)] - Successfully retrieved the configuration data"
                    ## Convert the output data (JSON) to powershell object ##
                    $updateData = ConvertFrom-Json $outputJson.Value[0].Message
                    if ($updateData[7].CheckResult -ne $null) {
                    $workspaceid = $updateData[7].CheckResult
                    } else {
                    $workspaceid = "NoWorkspace"
                }
                } else {
                    Write-Output "[$($vm.Name)] - Unexpected Error, manually collect update information"
                    $err = 'True'
                    $updateData = 'null'
                    $workspaceid = 'null'
                }
                } else {
                    Write-Output "[$($vm.Name)] - Unexpected Error, manually collect update information"
                    $err = 'True'
                    $updateData = 'null'
                    $workspaceid = 'null'
                }
                #Remove-Job -Id $vm_job.Id ## Removing the job can lead powershell to crash
                Receive-Job -Id $vm_job.Id -Keep
            }  
            elseif (($vm.osType -eq "Linux") -and ($vm.powerstate -like "*running")) {
                $timeout=''
                $vm_job = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunShellScript' -ScriptPath "C:\Scripts\$nixScript" -AsJob
                Wait-Job -Id $vm_job.Id -Timeout 300
                if ($(Get-Job -Id $vm_job.Id).State -eq "Running") {
                #Stop-Job -Id $vm_job.Id  ## Stopping the job can lead powershell to crash
                Write-Output "[$($vm.Name)] - Timed Out while getting VM configuration"
                $err = 'True'
                $updateData = 'null'
                $workspaceid = 'null'
                } elseif ($(Get-Job -Id $vm_job.Id).State -eq "Completed") {
                $garbageOutput = ''
                if ($garabageOutput = Get-Job -Id $vm_job.Id | Receive-Job -Keep | Select-Object -First 1) {
                    ## Convert the output data (JSON) to powershell object ##
                    $outputJson = ''
                    $outputJson = ($garabageOutput.Value[0].Message.Split([Environment]::NewLine))[2]
                    if ($outputJson) {
                    Write-Output "[$($vm.Name)] - Successfully retrieved the configuration data"
                    $updateData = ConvertFrom-Json $outputJson
                    if ($updateData[3].CheckResultMessageId -like "Linux.MultiHomingCheck.Passed") {
                        $workspaceid = ($updateData[3].CheckResultMessageArguments.split("'"))[1]
                    } else {
                        $workspaceid = "NoWorkspace"
                    }
                    } else {
                    Write-Output "[$($vm.Name)] - Data formatting error, manually collect update information"
                    $err = 'True'
                    $updateData = 'null'
                    $workspaceid = 'null'
                    }
                } else {
                    Write-Output "[$($vm.Name)] - Unexpected Error, manually collect update information"
                    $err = 'True'
                    $updateData = 'null'
                    $workspaceid = 'null'
                }
                } else {
                    Write-Output "[$($vm.Name)] - Unexpected Error, manually collect update information"
                    $err = 'True'
                    $updateData = 'null'
                    $workspaceid = 'null'
                }
                #Remove-Job -Id $vm_job.Id  ## Removing the job can lead powershell to crash
                Receive-Job -Id $vm_job.Id -Keep
            } 
            else {
                Write-Output "[$($vm.Name)] - VM not running or operating system not supported"
            }
        }

        if (($sqlRead.vmname -eq $vm.Name)) {
            Write-UpdateDataSQL -sqlInstance $SQLInstance -sqlDatabase $sqlDatabase -sqlCredential $sqlCredential $vm $updateData $workspaceid $err $sub
        } else {
            Write-NewDataSQL -sqlInstance $SQLInstance -sqlDatabase $sqlDatabase -sqlCredential $sqlCredential $vm $updateData $workspaceid $err $sub
        }
    }
}

Disable-AzContextAutosave –Scope Process | Out-Null

#Connect as automation SPN goes here
$RunAsConnectionName = 'AzureRunAsConnection'
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

New-Item -Path "C:\" -Name "Scripts" -ItemType "directory" -Force | Out-Null

Get-AzStorageAccount -ResourceGroupName $StorageAccountRG -AccountName $StorageAccount | `
  Get-AzStorageBlob -Container 'updatemanagement' -Blob *UMData* | `
  Get-AzStorageBlobContent -Destination "C:\Scripts" -Force | Out-Null

$sqlCredential = Get-AutomationPSCredential -Name $sqlCredentialName

$SPAutomationConnection = Get-AzAutomationConnection -AutomationAccountName "rmauto-dev" -Name $CustomerConnectionName -ResourceGroupName "rg-oms-dev"

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $SPAutomationConnection.FieldDefinitionValues.CertificateThumbprint `
        -ApplicationId $SPAutomationConnection.FieldDefinitionValues.ApplicationId `
        -Tenant $CustomerTenantId `
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

Save-AzContext -Path C:\Scripts\context.json -Force

$Jobs = @()
$Subscriptions = Get-AzSubscription

foreach ($sub in $Subscriptions) {

  Set-AzContext -Subscription $sub.Name | Out-Null

  Write-Output "Starting scan of Subscription - [$($sub.Name)]"
  
  $RunningJobs = $Jobs | Where-Object {$_.State -eq 'Running'}

  if ($RunningJobs.Count -ge $throttle) {
    Write-Output "Max job queue of [$($Throttle)] reached. Please wait while existing jobs are processed..."
    $RunningJobs | Wait-Job -Any | Out-Null
  }
  $Jobs += Start-Job -ScriptBlock $scriptblock -ArgumentList $SQLInstance, $sqlCredential, $sqlDatabase, $sub.Name, $CustomerTenantId, $ResourceGroupFilter, $CustomerConnectionName, $AutomationConnection
}

if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs | Receive-Job

$endTime = Get-TimeStamp

Write-Output "Script Start Time - [$($startTime)]"
Write-Output "Script End Time - [$($endTime)]"