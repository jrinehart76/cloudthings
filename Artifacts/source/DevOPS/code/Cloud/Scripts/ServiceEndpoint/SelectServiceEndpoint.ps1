Param(
    [parameter(Mandatory=$true)][string]$Location
)

# chooses service endpoint based off azure region
switch ($Location) {
   "EastUS"  {$SharedServiceSubnetResourceID = "/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-AM-EastUS-Prod-SS/providers/Microsoft.Network/virtualNetworks/VNET-AM-EastUS-Prod-SS/subnets/Subnet-AM-EastUS-Prod-SS-PANUnTrust"; break}
   "WestUS"   {$SharedServiceSubnetResourceID ="/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-AM-WestUS-SS-Networking/providers/Microsoft.Network/virtualNetworks/VNet-AM-WestUS-SS/subnets/Subnet-AM-WestUS-SS-PANUntrust"; break}
   "SoutheastAsia" {$SharedServiceSubnetResourceID ="/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-AP-SoutheastAsia-SS-Networking/providers/Microsoft.Network/virtualNetworks/VNET-AP-SoutheastAsia-SS/subnets/Subnet-AP-SoutheastAsia-SS-PANUnTrust"; break}
   "UKSouth"  {$SharedServiceSubnetResourceID ="/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-EU-UKSouth-SS-Networking/providers/Microsoft.Network/virtualNetworks/VNET-EU-UKSouth-SS/subnets/Subnet-EU-UKSouth-SS-PANUnTrust"; break}
   "ChinaEast2" {$SharedServiceSubnetResourceID ="/subscriptions/19edb65e-0ef2-40dd-9acb-72f7e7079f45/resourceGroups/RG-CN-ChinaEast2-SS-Networking/providers/Microsoft.Network/virtualNetworks/VNet-CN-ChinaEast2-SS/subnets/Subnet-CN-ChinaEast2-SS-PANUntrust"; break}
   "KoreaCentral" {$SharedServiceSubnetResourceID ="/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-AP-KoreaCentral-SS-Networking/providers/Microsoft.Network/virtualNetworks/VNet-AP-KoreaCentral-SS/subnets/Subnet-AP-KoreaCentral-SS-PANUntrust"; break}
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Location is not valid or does not have a matching service endpoint"
   }
}
    
Write-Host $SharedServiceSubnetResourceID

# Creates and Sets service endpoint variable
Write-Output "##vso[task.setvariable variable=SharedServiceSubnetResourceID]$($SharedServiceSubnetResourceID)"
