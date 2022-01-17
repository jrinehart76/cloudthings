## Purpose

`ADLS.json` deploys Azure Data Lake Store  

`ADLA.json` deploys an Analytics account on a ADLS account. 

## Assumptions -  ADLS.json

* data encryption is enabled
* Azure Key Vault manages the encryption key
  * you must create the key and pass in the parameters 


## Assumptions - ADLA.json

* ADLA acct name = ADLS acct name

uniqueString(resourceGroup().id)
