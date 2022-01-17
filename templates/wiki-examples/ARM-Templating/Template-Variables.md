
**VARIABLES**
Alphabetical list of all variables found within the ECS Azure Demo templates

| Variable| Definition | Example Values |
|----------------|-------------------------------------------------------|------------------|
| apiVersion | Version of the api  for each resource found within the template | 2017-11-01 |
| azureNetworkSubnet^nName | Name of the subnet | GatewaySubnet, APP, DATA|
| azureNetworkSubnet^nPrefix | Concatenation of the subnetOctet Variable and the last two octets of the address | 1.0/24 |
| azureRegion | Converts the resource group location to all CAPS for naming conventions | eastus -> EASTUS |
| basePrefix | Combination of parameters forming the base naming convention of a resource. Alias: namePrefix | |
| fqdn | Fully qualified domain name of the Public IP DNS Label | ipLabel.eastus.cloudapp.azure.com |
| gatewaySubnetName | Name of the GatewaySubnet.| required name: GatewaySubnet |
| gatewaySubnetNsgName | Name of network security group assigned to the gateway subnet | subnetname + 'NSG' derived from other variables |
| Maintenance Window | Dictate the window during which patching or other impacting maintenance can be performed. | FRI:22:00-SAT:04:00 |
| nsgName | Name of the network security group |  vmName + '-NSG' :: DEV-GLOBAL-EASTUS-AZDGLOBALDC1-NSG |
| publicIpAddressName | Name of the public ip address resource name | vmName + '-PIP' :: DEUSADM01-PIP |
| publicIpAddressSku |  The sku of the public ip address | 'Dynamic' or 'Static' |
| subnet^nNsgName | Name of network security group assigned to a subnet | subnetname + 'SUBNETNSG' derived from other variables|
| vmStorageAccountContainerName | Name of the Azure Storage Account Container containing the VHDs | vhds |
| vnetName | Name of the virtual network | PROD-GLOBAL-CORE-EASTUS-VNET |