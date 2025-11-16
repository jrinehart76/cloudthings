az login --username devuser@msp.com 

az account set --subscription subscription-dev-001
az account list

az group create --name rgTestDave --location "eastus2"

# ADLS
az group deployment create --resource-group rgTestDave --template-file ADLS.json

# keyvault:  AKV-AM-EastUS-DevOps-POC
# kvrg:  rg-region1-POC-SS
# keyName:  adlskey
# keyVersion:  4b76d54d85884a789d340a5bcd76e28d

#ADLA
az group deployment create --resource-group rgTestDave --template-file ADLA.json

#adlStoreName: adlsameastusdevlmx

az group delete --name rgTestDave