  <#
    .DESCRIPTION
        Installs Extensions on all customer virtual machines in a subscription

    .PREREQUISITES
        Account with access to customer Virtual Machines

    .DEPENDENCIES
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
        LASTEDIT: 2020.4.29

    .CHANGELOG

    .VERSION
        1.1.0
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

## Processes the VMs in a single subscription ##
$scriptblock = {
    param (
        [Parameter(Mandatory=$True)]
        [Object]$sub,
        [Parameter(Mandatory=$True)]
        [String]$ResourceGroup
    )

    ## Looks for a Diag storage account in the virtual machine region, creates one if not present ##
    function Process-DiagStorageAccount {
        param (
            [Parameter(Mandatory=$True)]
            [String]$VMLocation,
            [Parameter(Mandatory=$True)]
            [String]$SubName
        )

        Write-Output "Getting Diagnostic Storage - [$($VMLocation)] - [$($subName)]"
        try {
            $script:savmdiag = Get-AzStorageAccount | Where-Object {($_.StorageAccountName -like "savmdiag*") -and ($_.Location -eq $VMLocation)} | Select-Object -First 1
        } catch {
            Write-Error "Error getting Diagnostic Storage Account - [$($VMLocation)] - [$($subName)]"
        }
        if ($script:savmdiag) {
            Write-Output "Diagnostic Storage Account Found - [$($VMLocation)] - [$($script:savmdiag.StorageAccountName)] - [$($subName)]"
            $start = [System.DateTime]::Now.AddDays(-1)
            $end = [System.DateTime]::Now.AddYears(5)
            $script:stgkey = (Get-AzStorageAccountKey -Name $script:savmdiag.StorageAccountName -ResourceGroupName $script:savmdiag.ResourceGroupName).Value[0]
            $stgctx = New-AzStorageContext -StorageAccountName $script:savmdiag.StorageAccountName -StorageAccountKey $script:stgkey
            $script:stgtoken = New-AzStorageAccountSASToken -Service Blob,Table -ResourceType Service,Container,Object -Permission "racwdlup" -Context $stgctx
        }
        else {
            Write-Output "No Diagnostic Storage Account Found - [$($VMLocation)] - [$($subName)]"
            Write-Output "Creating Diagnostic Storage Account - [$($VMLocation)] - [$($subName)]"
            $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
            $result = ""
            for ($x = 0; $x -lt 13; $x++) {
                $result += $set | Get-Random
            }
            $rgname = "savmdiag-" + $VMLocation + "-rg"
            $saname = "savmdiag" + $result
            $rg = New-AzResourceGroup -Name $rgname -Location $VMLocation
            if ($rg) {
                $script:savmdiag = New-AzStorageAccount -ResourceGroupName $rgname -Name $saname -SkuName Standard_LRS -Location $rg.Location
                if ($script:savmdiag) {
                    Write-Output "Successfully Created Diagnostic Storage Account - [$($VMLocation)] - [$($stg.StorageAccountName)] - [$($subName)]"
                    $start = [System.DateTime]::Now.AddDays(-1)
                    $end = [System.DateTime]::Now.AddYears(5)
                    $StorageAccountName = $script:savmdiag.StorageAccountName
                    $script:stgkey = (Get-AzStorageAccountKey -Name $StorageAccountName -ResourceGroupName $script:savmdiag.ResourceGroupName).Value[0]
                    $stgctx = New-AzStorageContext -StorageAccountName $script:savmdiag.StorageAccountName -StorageAccountKey $script:stgkey
                    $script:stgtoken = New-AzStorageAccountSASToken -Service Blob,Table -ResourceType Container,Object -Permission "wlacu" -StartTime $start -ExpiryTime $end -Context $stgctx
                }
                else {
                    Write-Output "Could not create Diagnostic Storage Account - [$($VMLocation)] - [$($script:savmdiag.StorageAccountName)] - [$($subName)]"
                }
            }
            else {
                    Write-Error "Could not create Resource Group for Diagnostic Storage Account - [$($VMLocation)] - [$($script:savmdiag.StorageAccountName)] - [$($subName)]"
            }
        }
    }
    Set-AzContext -SubscriptionObject $sub
    $winExtension = 'Microsoft.Insights.VMDiagnosticsSettings'
    $nixExtension = 'LinuxDiagnostic'
    $WorkingDirectory = "C:\Scripts"
    $winConfig = 'windowsPublicSettings.json'
    $nixConfig = 'linuxPublicSettings.json'

    ## Get all virtual machines except AKS and Databricks ##
    $vms = @()
    $vms = Get-AzVm -Status -ResourceGroupName $ResourceGroup | `
            Where-Object { ($_.Name -notlike "aks-*") -and ($_.Name -notlike "k8*") -and ($_.StorageProfile.ImageReference.Offer -ne "Databricks") } | `
            Select-Object -Property Name,Id,Location,ResourceGroupName,powerstate,@{Name='osType'; Expression={$_.storageProfile.osDisk.osType}}
    if ($vms) {
        Write-Output "Found [$($vms.count)] VMs that match the Resource Group Name Filter - [$($ResourceGroup)]"
        Write-Output "VM Processing List: $($vms.Name)"
        ## Call the diag storage account function based on the region of the first VM ##
        Process-DiagStorageAccount -VMLocation $vm[0].Location -SubName $sub.Name

        ## Loop Through VMs ##
        foreach ($vm in $vms) {
            Write-Output "[$($vm.Name)] - Getting current extension configuration status"
            $VMEx = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                                      -VMName $vm.Name `
                                      -ErrorAction "SilentlyContinue"
            if ("Microsoft.Azure.Diagnostics" -in $VMEx.Publisher ) { 
                Write-Output "[$($vm.Name)] - Diagnostic extension is already installed." 
            }
            else {
                ## Check if the VM Location is different from the current diag storage account
                if ($script:savmdiag.Location -ne $vm.Location) {

                    ## Update the diag storage account variables when the VM Location has changed
                    Process-DiagStorageAccount -VMLocation $vm.Location -SubName $sub.Name
                }    
                Write-Output "[$($vm.Name)] - Diagnostics will be stored in [$($script:savmdiag.StorageAccountName)]"
                $singleVm = Get-AzVm -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
                try {

                    ## Update the VM boot diagnostics setting to use the specified storage account
                    $diagResult = Set-AzVMBootDiagnostic -VM $singleVm -Enable -ResourceGroupName $script:savmdiag.ResourceGroupName -StorageAccountName $script:savmdiag.StorageAccountName
                } catch { 
                    Write-Error "[$($vm.Name)] - VM Boot Diagnostics could not be set" 
                }
                if ($diagResult) {
                    Write-Output "[$($vm.Name)] - Boot Diagnostics setting successfully configured - [$($script:savmdiag.StorageAccountName)]"
                    if (($vm.osType -eq "Windows") -and ($vm.powerstate -like "*running")) {
                        Write-Output "[$($vm.Name)] - Installing Diagnostic VM Extension [$($winExtension)]"
                        try {
                            $DiagnosticsConfigurationPath = "${WorkingDirectory}/${winConfig}"
                            Set-AzVMDiagnosticsExtension -ResourceGroupName $vm.ResourceGroupName `
                                                        -VmName $vm.Name `
                                                        -Location $vm.Location `
                                                        -DiagnosticsConfigurationPath $diagnosticsConfigurationPath `
                                                        -StorageAccountName $script:savmdiag.StorageAccountName `
                                                        -StorageAccountKey $script:stgkey `
                                                        -NoWait
                        }
                        catch {
                            Write-Error "[$($vm.Name)] - Unable to Install [$($winExtension)]. May require manual installation."
                        }
                    }
                    elseif (($vm.osType -eq "Linux") -and ($vm.powerstate -like "*running")) {
                        Write-Output "[$($vm.Name)] - Installing Diagnostic VM Extension [$($nixExtension)]"
                        try {
                            $protectedSettings="{'storageAccountName': '$script:savmdiag.StorageAccountName', 'storageAccountSasToken': '$script:stgtoken', 'StorageAccountKey': '$script:stgkey'}"
                            $DiagnosticsConfigurationPath = "${WorkingDirectory}/${nixConfig}"
                            $configJson = Get-Content $diagnosticsConfigurationPath | Out-String
                            $configJson = $configJson.Replace('__DIAGNOSTIC_STORAGE_ACCOUNT__', $script:savmdiag.StorageAccountName)
                            $configJson = $configJson.Replace('__VM_RESOURCE_ID__', $vm.Id)
                            Set-AzVMExtension -Publisher Microsoft.Azure.Diagnostics `
                                            -ExtensionType LinuxDiagnostic `
                                            -Name LinuxDiagnostic `
                                            -ResourceGroupName $vm.ResourceGroupName `
                                            -VMName $vm.Name `
                                            -Location $vm.Location `
                                            -SettingString $configJson `
                                            -ProtectedSettingString $protectedSettings `
                                            -TypeHandlerVersion 3.0 `
                                            -NoWait
                        }
                        catch {
                            Write-Error "[$($vm.Name)] - Unable to Install [$($nixExtension)]. May require manual installation."
                        }
                    }
                    else {
                        Write-Error "[$($vm.Name)] - VM Not Running, or Error During Diagnostics installation"
                    }
                }
            }
        }
    } 
    else {
        Write-Output "No VMs found that match the Resource Group Name Filter - [$($ResourceGroup)]"
    }
}

Disable-AzContextAutosave –Scope Process | Out-Null

$RunAsConnectionName = 'AzureRunAsConnection'
$SPConnectionName = $CustSPN
$AutomationConnection = Get-AutomationConnection -Name $RunAsConnectionName

## Connect as the build-in RunAs account ##
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

## Get or update the extension configuration files ##
New-Item -Path "C:\" -Name "Scripts" -ItemType "directory" -Force | Out-Null

Get-AzStorageAccount -ResourceGroupName "rg-am-eastus" -AccountName "saameastusfuncapp" | `
  Get-AzStorageBlob -Container 'diagnostics' -Blob *PublicSettings.json | `
  Get-AzStorageBlobContent -Destination "C:\Scripts" -Force | Out-Null

$SPAutomationConnection = Get-AzAutomationConnection -AutomationAccountName $AutomationAccountName -Name $SPConnectionName -ResourceGroupName $AutomationAccountRG

## Connect using the customer SPN ##
Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $SPAutomationConnection.FieldDefinitionValues.CertificateThumbprint `
        -ApplicationId $SPAutomationConnection.FieldDefinitionValues.ApplicationId `
        -Tenant $CustTenantId `
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

## Get all subscriptions available to the customer SPN
$Subscriptions = Get-AzSubscription

## Iterate through the subscriptions, start the diag extension scriptblock for each
foreach ($sub in $Subscriptions) {
    Get-AzSubscription -SubscriptionName $sub.Name | Set-AzContext | Out-Null
    Write-Output "Starting scan of Subscription - [$($sub.Name)]"
    Invoke-Command -Scriptblock $scriptblock -ArgumentList $sub, $ResourceGroup
}

$endTime = Get-TimeStamp
Write-Output "Script Start Time - [$($startTime)]"
Write-Output "Script End Time - [$($endTime)]"
