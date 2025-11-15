

param(
[string][parameter(Mandatory=$true)]$ADGroup,
[string][parameter(Mandatory=$true)]$ResourceGroup,
[string][parameter(Mandatory=$true)]$Region
)

$ResourceGroupVMs = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupName $ResourceGroup
$ScriptPath = "D:/a/r1/a/_10thMagnitudeDevOps/code/EsteeCloud/Scripts/VMs/LocalAdmins/AzRunCommand.ps1"
Write-Host $ScriptPath
Write-Host "Azure VMs Detected: $($ResourceGroupVMs)"
foreach($vm in $ResourceGroupVMs){
    $OSType = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $vm.Name).StorageProfile.OsDisk.OsType
    if($OSType -eq "Windows"){
    $resp = Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroup -VMName $vm.Name -CommandId "RunPowershellScript" -ScriptPath $ScriptPath -Parameter @{AdGroupName=$ADGroup;Region=$Region}
    Write-Host "Added $($ADGroup) to list of local admins for vm: $($vm.Name)"
    }
    else{
    Write-Host "Did not add $($ADGroup) because vm $($vm.Name) is a Unix box"
    }
   
}



