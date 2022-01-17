az login --username dwentzel@10thmagnitude.com 

az account set --subscription ELC-AM-POC-DevOps
az account list

az group create --name rgTestDave --location EastUS

# logical sql server
az group deployment create --resource-group rgTestDave --template-file SQLServer.json

# asqldw
az group deployment create --resource-group rgTestDave --template-file asqldw.json
# 

# cleanup
az group delete --name rgTestDave

