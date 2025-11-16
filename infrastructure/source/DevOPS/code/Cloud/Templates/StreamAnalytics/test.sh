az login --username dwentzel@10thmagnitude.com 

az account set --subscription CUST-A-AM-POC-DevOps
az account list

az group create --name rgTestDave --location "eastus"
az group deployment create --resource-group rgTestDave --template-file ASA.json

az group delete --name rgTestDave