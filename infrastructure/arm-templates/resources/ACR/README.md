
# Azure ACR
This repository contains an ARM template to deploy ACR into Azure.

## ACR Notes

The ARM template deploys a Basic ACR SKU with no admin user enabled.  However, these can be easily overridden.

## Example Azure CLI Deployment

```
az group deployment create --template-file acr.json -g RG-AM-EastUS-POC-10M-CEP-ACR
```
