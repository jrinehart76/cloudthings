az login --username devuser@msp.com 

az account set --subscription subscription-dev-001
az account list

az group create --name rgTestDave --location EastUS

# logical sql server
az group deployment create --resource-group rgTestDave --template-file SQLServer.json

# asqldw
az group deployment create --resource-group rgTestDave --template-file asqldw.json
# 

# cleanup
az group delete --name rgTestDave

