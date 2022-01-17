<#########################################
The purpose of this script is to create
a new subnet and then add the appropriate, attach
appropriate NSG/Route Tables and add the
rule, if necessary, to the appropriate NSG for each subnet
##########################################
Example Run
.\Create-SubnetsAndRules.ps1 -subnetNames $subnetNames -VNetResourceGroup $VNetResourceGroup -virtualNetworkName $virtualNetworkName -AddressPrefixes $AddressPrefixes -location $location -Verbose
$subnetNames = "Subnet-AM-EastUS-NonProd-PaaS-Test-AppGW", "Subnet-AM-EastUS-NonProd-PaaS-Test-ASE", "Subnet-AM-EastUS-NonProd-PaaS-Test-APIM", "Subnet-AM-EastUS-NonProd-PaaS-Test-HDIKafka", "Subnet-AM-EastUS-NonProd-PaaS-Test-HDISpark", "Subnet-AM-EastUS-NonProd-PaaS-Test-Redis", "Subnet-AM-EastUS-NonProd-PaaS-Test-AKS", "Subnet-AM-EastUS-NonProd-PaaS-Test-DataBrick-Public", "Subnet-AM-EastUS-NonProd-PaaS-Test-DataBrick-Private"
$VNetResourceGroup = "Test-Subnet-Automation-Networking"
$AddressPrefixes = "10.7.5.0/24", "10.7.6.0/24", "10.7.7.0/24","10.7.8.0/24", "10.7.9.0/24", "10.7.10.0/24", "10.7.11.0/24", "10.7.12.0/24", "10.7.13.0/24"
$virtualNetworkName = "VNet-AM-EastUS-NonProd-PaaS"
$location = "eastus"
###########################################>

Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $vNetResourceGroup,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $virtualNetworkName,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $subnetNames,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String[]]
    $addressPrefixes,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true)]
    [String]
    $location

)

$ErrorActionPreference = "Stop"
#$DebugPreference = "Inquire"

#region Determine if Subnets align with AddressPrefixes
if ($subnetNames.Length -ne $AddressPrefixes.Length)
{
    Write-Error -Message "The number of subnets and address prefixes do not match" $subnetNames $addressPrefixes
}
#endregion

#region Get Virtual Network
try 
{
    $VNet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $VNetResourceGroup -Verbose
} 
catch
{
    Write-Output "Error occured retrieving Virtual Network: $($virtualNetworkName) Error: $_"
}
#endregion

$vNetTrim = $virtualNetworkName.TrimStart("VNet-")
for ($i = 0; $i -lt $subnetNames.Length; $i++)
{
    #region Get NSG and Route Table
    try 
    {

        if ($subnetNames[$i] -like '*databrick*')
        {
            $NetworkSecurityGroup = Get-AzNetworkSecurityGroup -ResourceGroupName $VNetResourceGroup -Name "NSG-$($vNetTrim)-databrick" | where {$_.Name -match $location}

        }
        else
        {
            $NetworkSecurityGroup = Get-AzNetworkSecurityGroup -ResourceGroupName $VNetResourceGroup -Name "NSG-$($vNetTrim)" |  where {$_.name -match $location}
        }

        if ($subnetNames[$i] -like '*APIM*' -or $subnetNames[$i] -like '*AppGW*' -or $subnetNames[$i] -like '*ISE*'  -or $subnetNames[$i] -like '*HDI*' -or $subnetNames[$i] -like '*databrick*public' )
        {
            $DirectToInternetTraffic = $true
            $RouteTable = Get-AzRouteTable -Name "RouteTable-$($VnetTrim)-DirectToInternet" -ResourceGroupName $VNetResourceGroup | where {$_.name -match $location}
        }
        elseif ($subnetNames[$i] -like '*ASE')
        {
            $DirectToInternetTraffic = $false
            $RouteTable = Get-AzRouteTable -Name "RouteTable*ASE" -ResourceGroupName $VNetResourceGroup | where {$_.name -match $location}
        }
        else
        {
            $DirectToInternetTraffic = $false
            $RouteTable = Get-AzRouteTable -Name "RouteTable-$($VnetTrim)-SubnetsToNVA" -ResourceGroupName $VNetResourceGroup | where {$_.name -match $location}
        }

    }
    catch {
        Write-Error "Error retrieving NSG or Route Table: $_"
    }

    #endregion
    #region Add the subnet 
    try
    {
        if ($subnetNames[$i] -like ("*databrick*"))
        {
            $delegation = New-AzDelegation -Name "Delegation-$($subnetNames[$i]))" -ServiceName "Microsoft.Databricks/workspaces"
            Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $subnetNames[$i] -AddressPrefix $AddressPrefixes[$i] -NetworkSecurityGroup $NetworkSecurityGroup -RouteTable $RouteTable -Delegation $delegation -Verbose
            $VNet | Set-AzVirtualNetwork -Verbose
        }
        else
        {
            Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name $subnetNames[$i] -AddressPrefix $AddressPrefixes[$i] -NetworkSecurityGroup $NetworkSecurityGroup -RouteTable $RouteTable -Verbose
            $VNet | Set-AzVirtualNetwork -Verbose

        }
    }
    catch
    {
        Write-Error "Failed to add the subnet $($subnetNames[$i]). Error: $_"
    }
    #endregion
    #region Edit the Inbound NSG Rule
    try
    {
        $SecurityRuleName = $null  
        
        if ($DirectToInternetTraffic -eq $true)
        {
        switch -Wildcard ($subnetNames[$i])
            {
                "*AppGW*" {$SecurityRuleName = "AllowAppGWMgmtInbound"; Break}
                "*ASE*" {$SecurityRuleName = "AllowASEMgmtInbound"; Break}
                "*HDIKafka*" {$SecurityRuleName = "AllowHDIMgmtInbound"; Break}
                "*HDISpark*" {$SecurityRuleName = "AllowHDIMgmtInbound"; Break}
                "*APIM*" {$SecurityRuleName = "AllowAPIMMgmtInbound"; Break}
            }
        }
            
        #Only add Ip Address to NSG if necessary
        if ($SecurityRuleName -ne $null)
        {
            #Add to NSG Rule only if it does not exist
            $InboundSecurityRule = Get-AzNetworkSecurityRuleConfig -Name $SecurityRuleName -NetworkSecurityGroup $NetworkSecurityGroup -Verbose
                if ($InboundSecurityRule.DestinationAddressPrefix -notcontains "$($AddressPrefixes[$i])")
                {
                    $InboundSecurityRule.DestinationAddressPrefix.Add($AddressPrefixes[$i])
                    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NetworkSecurityGroup        
                }
        }

    }
    catch
    {
        Write-Output "Failed to edit inbound security rule $($SecurityRuleName). Error: $_"
    }
    #endregion
}
