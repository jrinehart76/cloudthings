param (
    [string][parameter(Mandatory=$true)]$vnetResourceGroup,
    [string][parameter(Mandatory=$true)]$vnetName,
	[string][parameter(Mandatory=$true)]$subnetName,
	[string][parameter(Mandatory=$true)]$aksSPNAppID
)

New-AzRoleAssignment -ResourceType "Microsoft.Network/virtualNetworks/subnets" -ResourceGroupName $vnetResourceGroup -ResourceName $subnetName `
					 -ApplicationId $aksSPNAppID -RoleDefinitionName "Contributor" -ParentResource "virtualNetworks/$vnetName"