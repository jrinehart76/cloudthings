#.\Create-VirtualNetwork.ps1 -NewVNetResourceGroupName $NewVNetResourceGroupName -region $region -environment $environment -application $application -location $location -NewVNetAddressPrefix $NewVNetAddressPrefix -DNSServersStaticIPs 10.0.1.5,10.0.1.6 -PrimaryFunction $PrimaryFunction -WebSubnetAddressPrefix $WebSubnetAddressPrefix -AppSubnetAddressPrefix $AppSubnetAddressPrefix -DBSubnetAddressPrefix $DBSubnetAddressPrefix -VMSSubnetAddressPrefix $VMSSubnetAddressPrefix -BusinessOwner $BusinessOwner -subscriptionName $subscriptionName
Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $NewVNetResourceGroupName,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $region,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $environment,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $application,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $location,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $NewVNetAddressPrefix,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $DNSServersStaticIPs,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $PrimaryFunction,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $WebSubnetAddressPrefix,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $AppSubnetAddressPrefix,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $DBSubnetAddressPrefix,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $VMSSubnetAddressPrefix,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $BusinessOwner,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $subscriptionName
)

$ErrorActionPreference = "Stop"

#Set Variables for the region
Select-AzSubscription -Subscription GCCS
Switch ($location)
{
    'EastUS' {$DNSVMNamePrefix = 'US-AZR'; $HubVNetResourceGroupName = 'RG-AM-EastUS-Prod-SS'}
    'WestUS' {$DNSVMNamePrefix = 'US-AZ2'; $HubVNetResourceGroupName = 'RG-AM-WestUS-SS-Networking'}
    'SoutheastAsia' {$DNSVMNamePrefix = 'SG-AZR'; $HubVNetResourceGroupName = 'RG-AP-SoutheastAsia-SS-Networking'}
    'UKSouth' {$DNSVMNamePrefix = 'GB-AZR'; $HubVNetResourceGroupName = 'RG-EU-UKSouth-SS-Networking'}
    'ChinaEast2' {$DNSVMNamePrefix = 'CN-AZR'; $HubVNetResourceGroupName = 'RG-CN-ChinaEast2-SS-Networking'}
}

#Step Get Routes from Hub VNet Route Tables and limit to properties needed to create route tables
$HubSubnetsToNVARouteTable = Get-AzRouteTable -ResourceGroupName $HubVNetResourceGroupName -Name "RouteTable-$($region)-$($location)-SS-SubnetsToNVA"
$HubGatewayRouteTable = Get-AzRouteTable -ResourceGroupName $HubVNetResourceGroupName -Name "RouteTable-$($region)-$($location)-SS-GatewayToNVA"
$HubSubnetsToNVARoutes = Get-AzRouteConfig -RouteTable $HubSubnetsToNVARouteTable | Select-Object Name, AddressPrefix, NextHopType, NextHopIpAddress
$HubGatewayRoutes = Get-AzRouteConfig -RouteTable $HubGatewayRouteTable | Select-Object Name, AddressPrefix, NextHopType, NextHopIpAddress

#Select Subscription where networking resources are to be deployed
Select-AzSubscription -Subscription $subscriptionName
New-AzNetworkSecurityGroup -Name "NSG-$($region)-$($location)-$($application)-$($environment)" -ResourceGroupName $NewVNetResourceGroupName -Location $location
$NewVNetNSG = Get-AzNetworkSecurityGroup -Name "NSG-$($region)-$($location)-$($application)-$($environment)" -ResourceGroupName $NewVNetResourceGroupName
New-AzRouteTable -ResourceGroupName $NewVNetResourceGroupName -Location $location -Name "RouteTable-$($region)-$($location)-$($environment)-$($application)-SubnetsToNVA" 
New-AzRouteTable -ResourceGroupName $NewVNetResourceGroupName -Location $location -Name "RouteTable-$($region)-$($location)-$($environment)-$($application)-DirectToInternet"
$NewVNetSubnetsToNVARouteTable = Get-AzRouteTable -ResourceGroupName $NewVNetResourceGroupName -Name "RouteTable-$($region)-$($location)-$($environment)-$($application)-SubnetsToNVA"
$NewVNetDirectToInternetRouteTable = Get-AzRouteTable -ResourceGroupName $NewVNetResourceGroupName -Name "RouteTable-$($region)-$($location)-$($environment)-$($application)-DirectToInternet"

#Populate new Route Tables
foreach ($HubSubnetsToNVARoute in $HubSubnetsToNVARoutes)
{
    $NewVNetSubnetsToNVARouteTable | Add-AzRouteConfig -Name $HubSubnetsToNVARoute.Name -AddressPrefix $HubSubnetsToNVARoute.AddressPrefix -NextHopType $HubSubnetsToNVARoute.NextHopType -NextHopIpAddress $HubSubnetsToNVARoute.NextHopIpAddress
}
$NewVNetSubnetsToNVARouteTable | Set-AzRouteTable

foreach ($HubGatewayRoute in $HubGatewayRoutes)
{
    $NewVNetDirectToInternetRouteTable | Add-AzRouteConfig -Name $HubGatewayRoute.Name -AddressPrefix $HubGatewayRoute.AddressPrefix -NextHopType $HubGatewayRoute.NextHopType -NextHopIpAddress $HubGatewayRoute.NextHopIpAddress
}
$NewVNetDirectToInternetRouteTable | Set-AzRouteTable

#Deploy VNET
$NewVNetTags = @{BusinessOwner="$($BusinessOwner)"; CostCenter="9943058392"; Department="Products and Platforms"; Environment="$($environment)"; Location="$($location)"; PrimaryFunction="$($PrimaryFunction)"; Region="$($region)"}

$VMSSubnetAddressSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name "Subnet-$($region)-$($location)-$($environment)-$($application)-VMS" -AddressPrefix $VMSSubnetAddressPrefix -NetworkSecurityGroup $NewVNetNSG -RouteTable $NewVNetSubnetsToNVARouteTable
$AppSubnetAddressSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name "Subnet-$($region)-$($location)-$($environment)-$($application)-App" -AddressPrefix $AppSubnetAddressPrefix -NetworkSecurityGroup $NewVNetNSG -RouteTable $NewVNetSubnetsToNVARouteTable
$DBSubnetAddressSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name "Subnet-$($region)-$($location)-$($environment)-$($application)-DB" -AddressPrefix $DBSubnetAddressPrefix -NetworkSecurityGroup $NewVNetNSG -RouteTable $NewVNetSubnetsToNVARouteTable
$WebSubnetAddressSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name "Subnet-$($region)-$($location)-$($environment)-$($application)-Web" -AddressPrefix $WebSubnetAddressPrefix -NetworkSecurityGroup $NewVNetNSG -RouteTable $NewVNetSubnetsToNVARouteTable
New-AzVirtualNetwork -Name "VNET-$($region)-$($location)-$($environment)-$($application)" -ResourceGroupName $NewVNetResourceGroupName -Location $location -AddressPrefix $NewVNetAddressPrefix -DnsServer $DNSServersStaticIPs -Subnet $VMSSubnetAddressSubnetConfig,$WebSubnetAddressSubnetConfig,$AppSubnetAddressSubnetConfig,$DBSubnetAddressSubnetConfig -Tag $NewVNetTags
$NewVNet = Get-AzVirtualNetwork -Name "VNET-$($region)-$($location)-$($environment)-$($application)" -ResourceGroupName $NewVNetResourceGroupName

#Construct Name of DNS Servers
$DNSServers = Search-AzGraph -Query "where type =~ 'Microsoft.Compute/virtualMachines' | where name contains 'PUDNS' | where name contains '$($DNSVMNamePrefix)' | project name | sort by name"
$FirstDNSServerName = ($DNSVMNamePrefix + '-PUDNS' + ($DNSServers.Count + 1)).padLeft(2,'0')
$SecondDNSServerName =  ($DNSVMNamePrefix + '-PUDNS' + ($DNSServers.Count + 2)).padLeft(2,'0')

#Deploy DNS Servers 


#Capture Internal DNS Suffix of DNS Servers NICs and output the names
$FirstDNSServerNIC = Search-AzGraph -Query "where type =~ 'Microsoft.Network/NetworkInterfaces' | where name contains '$($FirstDNSServerName)'"
$SecondDNSServerNIC = Search-AzGraph -Query "where type =~ 'Microsoft.Network/NetworkInterfaces' | where name contains '$($SecondDNSServerName)'"












