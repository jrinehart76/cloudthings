<#
    This script will add an SSH public key to one or more VMs,
    with the intent of using this in conjunction with Ansible.
    Assumed to run with an Azure PowerShell task in AzDO, 
    specifying the subscription.
#>
param (
    [string]
    [parameter(Mandatory=$true,HelpMessage="The name of the admin user for the machine (i.e. cloudadmin).")]
    $AdminUser,
    [string]
    [parameter(Mandatory=$true, HelpMessage="The name of the key vault containing the subscription-level Ansible secrets.")]
    $KeyVaultName,
    [switch]
    [parameter(HelpMessage="Flag used to indicate whether this will be run for a single VM.")]
    $SingleVM,
    [string]
    [parameter(HelpMessage="Required if using the SingleVM flag.  The name of the virtual machine to onboard.")]
    $SingleVMName,
    [string[]]
    [parameter(HelpMessage="Optional parameter to pass in multiple VM names.")]
    $VMNames,
    [string]
    [parameter(HelpMessage="Optional parameter to pass in the RG of the VM(s) to query.  Useful for query limiting.")]
    $ResourceGroupName
)

if($AdminUser -eq "") {
    Write-Error "AdminUser cannot be an empty string."
    exit -3
}

if($SingleVM.IsPresent -and [System.String]::IsNullOrEmpty($SingleVMName)) {
    Write-Error "Cannot pass the SingleVM flag without a VM Name."
    exit -1
}


if($SingleVM.IsPresent) {
    # Query for only one VM
    $vms = Get-AzVM -Name $SingleVMName -Status
} elseif($VMNames -ne $null -and ($ResourceGroupName -eq "" -or $ResourceGroupName -eq $null)) {
    # Query for the list of VMs
    $vms = Get-AzVM -Status | ? { $_.Name -in $VMNames }
} elseif ($VMNames -eq $null -and ![System.String]::IsNullOrEmpty($ResourceGroupName)) {
    $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status
} else {
    # Query for the entire subscription
    $vms = Get-AzVM -Status 
}

$vms = $vms | ? { $_.storageProfile.osDisk.osType -eq "Linux" -and $_.ResourceGroupName -notlike "MC_*" -and $_.PowerState -eq "VM running" }

(Get-AzKeyVaultSecret -VaultName "$($KeyVaultName)" -Name "ansible-public-ssh-key").SecretValueText | Out-File pubkey.pub
$pubkey = Get-Content -Path pubkey.pub
"su - $($AdminUser) && mkdir -p /home/$($AdminUser)/.ssh && grep -qxF '$($pubkey)' /home/$($AdminUser)/.ssh/authorized_keys || echo '$($pubkey)' >> /home/$($AdminUser)/.ssh/authorized_keys" | Out-File appendkey.sh

if($vms.Count -eq 0) {
    Write-Warning "No VM(s) were found as a result of this query.  No action taken."
    exit 0
}

foreach($vm in $vms) {
    $task = ($vm | Invoke-AzVmRunCommand -CommandId RunShellScript -ScriptPath appendkey.sh)
    Write-Output $task.Message
    Write-Output "Updated ssh authorized keys on $($vm.Name)."
}