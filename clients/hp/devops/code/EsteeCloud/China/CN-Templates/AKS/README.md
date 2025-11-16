
# Azure AKS
This repository contains an ARM template to deploy AKS into an existing VNet with custom IP addressing and Azure CNI for IP address allocation.

## Address ranges

The IP address plan used for this cluster consists of a VNET, a Subnet (VNET-Local) reserved for other resources, and a Subnet (AKS-Nodes) reserved for AKS agent nodes and Pods.


## Static IPs

| Address | Description |
| ------- | ----------- |
| 172.16.0.1/24 | IP address and netmask (CIDR notation) for the Docker bridge address. |
| 15.15.3.5 | IP address reserved from the Kubernets Service range used for DNS. |

**Note:** The Docker bridge network in the template defaults to 172.16.0.0/24 but can be overridden.

**Note 2:** 15.15.3.5 is an example IP based.  Set the IP to something within the range of the subnet being deployed to.  (`Variable name: serviceCidr`)

## Example Azure CLI Deployment

```
az group deployment  create --template-file aks.json -g RG-AM-EastUS-POC-MSP-CEP-AKS --parameters azureServicePrincipalAppId=<SPappId> azureServicePrincipalAppKey=<SPKey> nodeSSHPublicKey=<sshKey>  serviceCidr=15.15.3.0/24 dnsServiceIP=15.15.3.5
```
