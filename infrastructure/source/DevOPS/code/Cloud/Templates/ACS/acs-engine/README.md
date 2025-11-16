
# Azure acs-engine
This repository contains an example configuration file for acs-engine.

## Notes

This basic configuration contains a base deployment for Kubernetes. It deploys a Kubernetes 1.10 cluster with 1 Master and 3 Nodes onto a customer VNET.

Please see  https://github.com/Azure/acs-engine for details about the acs-engine configuration specifications.

An acs-engine Kubernetes cluster deployment is a two step process:
   1. Create the acs-engine configuration file and use `acs-engine generate` to generate the ARM templates
   2. Use azure cli or powershell to deploy the template

## Example Azure CLI Deployment

```
acs-engine generate poc-k8s-azurenet.json

az group create --name RG-AM-EastUS-POC-MSP-CEP-ACS-ENGINE --location EastUS

az group deployment create --name "acs-engine-1" --resource-group RG-AM-EastUS-POC-MSP-CEP-ACS-ENGINE --template-file "./_output/CUST-A-am-eastus-cep-k8s/azuredeploy.json" --parameters "./_output/CUST-A-am-eastus-cep-k8s/azuredeploy.parameters.json"
```
