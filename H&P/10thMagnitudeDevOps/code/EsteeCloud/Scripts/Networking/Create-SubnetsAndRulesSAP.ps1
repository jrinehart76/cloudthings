<#########################################
The purpose of this script is to create
a new subnet to an SAP VNET. Because of the 
potential use for NFS, this script will add any non-NFS
subnets as routes to the appropriate route table so that
synchronous routing can occur.
##########################################
Example Run
.\Create-SubnetsAndRulesSAP.ps1 -SubnetTypes $subnetTypes -region $region -location $location -Environment $environment -VNetResourceGroup $VNetResourceGroup -AddressPrefix $AddressPrefix -Verbose
$subnetTypes = "NFS", "AppGW", "VMs"
$region = "AM"
$location = "EastUS"
$environment = "NonProd"
$VNetResourceGroup = "Subnet_Automation"
$AddressPrefix = "10.23.1.0/24", "10.23.2.0/24", "10.23.3.0/24"
###########################################>

Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $SubnetTypes,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [ValidateSet("AM", "CN", "AP", "EU")]
    [String]
    $region,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [ValidateSet("EastUS", "WestUS", "ChinaEast2", "SoutheastAsia", "UKSouth")]
    [String[]]
    $location,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [ValidateSet("Prod","NonProd")]
    [String[]]
    $environment,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $VNetResourceGroup,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $AddressPrefix
)

$ErrorActionPreference = "Stop"
#$DebugPreference = "Inquire"

#region Determine if Subnets align with AddressPrefixes
if ($SubnetTypes.Length -ne $AddressPrefix.Length)
{
    Write-Error -Message "The number of subnets and address prefixes do not match. Please ensure you have entered the correct number of Address Prefixes that align with the Subnet Types"
}
#endregion

#region Get Virtual Network
$VNetName = "VNet-$($region)-$($location)-$($environment)-SAP"

try 
{
    $VNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $VNetResourceGroup -Verbose
} 
catch
{
    Write-Output "Error occured retrieving Virtual Network: $($VnetName) Error: $_"
}
#endregion

#region add the subnet(s) and update the routes
for ($i = 0; $i -lt $SubnetTypes.Length; $i++)
{
    $SubnetName = "Subnet-$($region)-$($location)-$($environment)-SAP-$($SubnetTypes[$i])"

    if ($SubnetTypes[$i] -eq 'APIM' -or $SubnetTypes[$i] -like 'AppGW' -or $SubnetTypes[$i] -like 'ASE')
    {
        $RouteTable = "RouteTable-$($region)-$($location)-$($environment)-SAP-DirectToInternet"
    }
    else 
    {
        $RouteTable = "RouteTable-$($region)-$($location)-$($environment)-SAP-SubnetsToNVA"
    }

    $NetworkSecurityGroup = "NSG-$($region)-$($location)-$($environment)-SAP"

    #Will need the  Route Table no matter if NFS or other subnet
    $RTObject = Get-AzRouteTable -ResourceGroupName $VNetResourceGroup -Name $RouteTable

    #Add the subnet 
    try
    {
        if ($SubnetName.Contains("NFS"))
        {
            $delegation = New-AzDelegation -Name "Delegation-$($region)-$($location)-$($environment)-NFS" -ServiceName "Microsoft.Netapp/volumes"
            Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName -AddressPrefix $AddressPrefix[$i] -Delegation $delegation
            $VNet | Set-AzVirtualNetwork -Verbose
        }
        else 
        {
            $NSGObject = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroup -ResourceGroupName $VNetResourceGroup
            Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $SubnetName -AddressPrefix $AddressPrefix[$i] -NetworkSecurityGroup $NSGObject -RouteTable $RTObject
            $VNet | Set-AzVirtualNetwork -Verbose
            try 
            {
                $RTObjectRoutePrefixes = $RTObject.Routes.Addressprefix
                if ($AddressPrefix[$i] -in $RTObjectRoutePrefixes)
                {
                    Write-Output "This address prefix already has a route. Prefix: $($AddressPrefix[$i])"
                }
                else 
                {
                    Add-AzRouteConfig -Name "UDR-$($SubnetName)" -RouteTable $RTObject -AddressPrefix $AddressPrefix[$i] -NextHopType VirtualAppliance -NextHopIpAddress 10.252.127.134 | Set-AzRouteTable
                }
            }
            catch 
            {
                Write-Error "Could not add route. Error: $_"
            }
        }
    }
    catch
    {
        Write-Error "Error: $_"
    }
}
#endregion
