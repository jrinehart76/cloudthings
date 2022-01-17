
Param(
[string]$cosmosRGName = "RG-AM-EastUS-POC-10M-CEP-CosmosDB",
[string]$apiVersion = "2015-04-08",
[string]$acctName = "cosdb-am-eastus-poc",
[string]$isVirtualNetworkFilterEnabled ="True",
[string]$subnetid = "/subscriptions/8a00b99b-04e8-474d-a318-397385dc07a4/resourceGroups/RG-AM-EastUS-Prod-SS/providers/Microsoft.Network/virtualNetworks/VNET-AM-EastUS-Prod-SS/subnets/Subnet-AM-EastUS-Prod-SS-PANUnTrust"
)

#$vnProp = Get-AzureRmVirtualNetwork -Name $vnName  -ResourceGroupName $vnRGName

$cosmosDBConfiguration = Get-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
  -ApiVersion $apiVersion `
  -ResourceGroupName $cosmosRGName `
  -Name $acctName

if($cosmosDBConfiguration.Properties.isVirtualNetworkFilterEnabled -eq $False)
{
write-host 'Updating CosmosDB Virtual Network Settings' -ForegroundColor Green
$location = @(@{"locationName"="East US"; "failoverPriority"=0}, 
               @{"locationName"="West US"; "failoverPriority"=1})

$consistencyPolicy = @{}
$cosmosDBProperties = @{}

$consistencyPolicy = $cosmosDBConfiguration.Properties.consistencyPolicy

$accountVNETFilterEnabled = $True
#$subnetID = $vnProp.Id+"/subnets/" + $sname  
$virtualNetworkRules = @(@{"id"=$subnetID})
$databaseAccountOfferType = $cosmosDBConfiguration.Properties.databaseAccountOfferType


$cosmosDBProperties['databaseAccountOfferType'] = $databaseAccountOfferType
$cosmosDBProperties['locations'] = $location
$cosmosDBProperties['consistencyPolicy'] = $consistencyPolicy
$cosmosDBProperties['virtualNetworkRules'] = $virtualNetworkRules
$cosmosDBProperties['isVirtualNetworkFilterEnabled'] = $accountVNETFilterEnabled
#$cosmosDBProperties['ipRangeFilter'] = "10.0.0.4/24,10.0.0.5,10.0.0.6"

Set-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion $apiVersion -ResourceGroupName $cosmosRGName -Name $acctName -Properties $cosmosDBProperties -force
}
Else{
write-host 'CosmosDB Up-to-date' -ForegroundColor Green

}