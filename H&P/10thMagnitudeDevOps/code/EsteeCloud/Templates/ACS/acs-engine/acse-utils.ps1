param(
	[string]
	[parameter(Mandatory=$true)]
	$FirstStaticIP,
	[string]
	[parameter(Mandatory=$true)]
	$VnetCIDR,
	[string]	
	[parameter(Mandatory=$true)]
	$FilePath
)

# requires Chocolatey to be installed
choco install acs-engine -y
# Swap out the default CIDR and static IP reservation
(cat $($FilePath)/poc-k8s-azurenet.json).Replace("1.1.1.250","$($FirstStaticIP)").Replace("1.1.1.0/24","$($VNetCIDR)") `
| Out-File $($FilePath)/acsengine.json -Encoding ASCII
