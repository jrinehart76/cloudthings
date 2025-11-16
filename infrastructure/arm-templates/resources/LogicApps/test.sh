az login --username devuser@msp.com 

az account set --subscription subscription-dev-001
az account list

az group create --name rgTestDave --location "eastus"
az group deployment create --resource-group rgTestDave --template-file LogicApps.json

az group delete --name rgTestDave