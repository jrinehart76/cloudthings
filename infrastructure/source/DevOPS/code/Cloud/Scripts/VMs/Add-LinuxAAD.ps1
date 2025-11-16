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
$groups = "00000000-0000-0000-0000-000000000000","00000000-0000-0000-0000-000000000000","00000000-0000-0000-0000-000000000000","00000000-0000-0000-0000-000000000000"
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
