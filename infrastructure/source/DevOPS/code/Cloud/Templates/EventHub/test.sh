az login --username dwentzel@10thmagnitude.com 

az account set --subscription CUST-A-AM-POC-DevOps
az account list

az group deployment create --resource-group rgTestDave --template-file EventHub.json

az group delete --name rgTestDave