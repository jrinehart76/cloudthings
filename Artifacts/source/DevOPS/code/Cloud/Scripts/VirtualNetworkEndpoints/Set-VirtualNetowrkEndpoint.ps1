$vnet = Get-AzureRmVirtualNetwork -Name $(virtualNetworkName) -ResourceGroupName $(resourceGroupName)
$vnetconfig = Set-AzureRmVirtualNetworkSubnetConfig -Name $(subnetName) -AddressPrefix $(subnetAddressPrefix) -VirtualNetwork $vnet -ServiceEndpoint $(endpointType)
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet