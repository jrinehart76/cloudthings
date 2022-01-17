<#
Sets name resolution and DNS searching for ACS Engine-generated VMs
#>
param (
	[string]
	[parameter(Mandatory=$true)]
	$ResourceGroup,
	[string]
	[parameter(Mandatory=$true)]
	$FirstConsecutiveIP,
	[string]
	[parameter(Mandatory=$true)]
	$ClusterDnsPrefix,
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	[parameter(Mandatory=$true)]
	$ScriptPath,
	[switch]
	$WhatIf
)
$vms = Get-AzureRmVM -ResourceGroupName $ResourceGroup
$IpInfo = @()
foreach($vm in $vms) 
{
  $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
  $nic = Get-AzureRmNetworkInterface -Name ($nicId.Split('/')[-1]) -ResourceGroupName $ResourceGroup
  $dns = $nic.DnsSettings.InternalDomainNameSuffix
  (cat $ScriptPath) -replace "#{InternalDns}#",$dns `
					-replace "#{Location}#",$Location `
					-replace "#{ClusterDnsPrefix}#",$ClusterDnsPrefix `
					-replace "#{FirstConsecutiveIP}#",$FirstConsecutiveIP `
					| Out-File ./acs-updated.sh
  $IpInfo += @{
  	  VMName = $vm.Name
	  IP = $nic.IpConfigurations[0].PrivateIpAddress
  }
}
foreach($info in $IpInfo) {
	"echo '$($info.IP) $($info.VMName)' >> /etc/hosts" | Out-File ./acs-updated.sh -Append
}

if(!($WhatIf.IsPresent)) {
	foreach($vm in $vms) {
		Invoke-AzureRmVMRunCommand -ResourceGroupName $ResourceGroup -VMName $vm.Name -CommandId RunShellScript -ScriptPath ./acs-updated.sh
	}
} else {
	Write-Output "Since this is a test, the script that would have been deployed is shown below."
	Write-Output (cat ./acs-updated.sh)
}