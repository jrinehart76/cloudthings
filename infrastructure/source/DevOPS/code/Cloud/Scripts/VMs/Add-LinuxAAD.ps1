<#
# This will install the Linux AAD login script onto all machines 
# in the specified resource group and grant Virtual Machine Administrator Login
# to any groups specified.
#>
param (
    [string]
    [parameter(Mandatory=$true)]
    $ResourceGroup,
    [string[]]
    $AadGroups,
    [switch]
    $ExtensionOnly,
    [switch]
    $PermissionsOnly
)

# Add in the default groups for access - MSP DevOps, MSP Support, SRE
$groups = "576f05b2-09e4-4246-aa10-53538aab1dd0","bc6f093e-2526-4361-b639-7f179cd7d70c","c65be177-dda6-4bd9-bd1b-31630fbd794a","61f29c52-1f39-4ed7-94bc-4933c6f87e2b"
if($AadGroups -ne $null) {
    $groups = $groups + $AadGroups
}


$vms = Get-AzVM -ResourceGroupName $ResourceGroup

foreach($vm in $vms.Where( {$_.Extensions.Where({ !($_.Id.Contains("AADLoginForLinux"))})}) ) {
    Write-Output "Processing $($vm.Name)"
    if($ExtensionOnly.IsPresent -or ($ExtensionOnly.IsPresent -eq $false -and $PermissionsOnly.IsPresent -eq $false)) {
    Set-AzVMExtension `
    -Publisher Microsoft.Azure.ActiveDirectory.LinuxSSH `
    -Name AADLoginForLinux `
    -ResourceGroupName $ResourceGroup `
    -VMName $vm.Name -Location $vm.Location -ExtensionType "AADLoginForLinux" 
    }
    if($PermissionsOnly.IsPresent -or ($ExtensionOnly.IsPresent -eq $false -and $PermissionsOnly.IsPresent -eq $false)) {
        foreach($group in $groups) {
        if([System.Guid]::Parse($group)) {
            New-AzRoleAssignment `
            -RoleDefinitionName "Virtual Machine Administrator Login" `
            -ObjectId ([System.Guid]::Parse($group)) `
            -Scope $vm.Id -ErrorAction Ignore
        }

        }
    }
    

}
