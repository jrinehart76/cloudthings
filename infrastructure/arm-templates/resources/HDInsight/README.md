## ⚠️ Consider Modern Alternatives

**HDInsight is still fully supported**, but for new workloads consider:
- **Azure Synapse Analytics Spark Pools** - Serverless Spark with better integration
- **Azure Databricks** - Enhanced Spark with collaborative notebooks and MLflow

These templates remain valid for HDInsight deployments, but evaluate modern alternatives for new projects.

---

## Purpose

Creates an HDI cluster, either:

* base
  * always deploys with ADLS as secondary storage.  
  * ADLS must exist
  * ensure clustertype is set to `hadoop` and not `spark` in `HDI-base.json`
* spark
  * simply change the clustertype from `hadoop` to `spark` in `HDI-base.json`
  * Otherwise there is no difference between `hadoop` and `spark` 
* hdi standalone
  * same as `spark` and `bases` above but 
    * called from `HDI-standalone.json` 
    * does NOT utilize ADLS (new requirement in new Data Lake architecture from Jai)
* kafka
  * kafka should never require ADLS or add'l storage accounts
  * kafka cluster has hardcoded zookeepernode parameters.  Zookeeper is similar to supervisord and should not ever need to be changed.
  * use `HDI-kafka.json` to deploy a kafka cluster


You can use `base64_helper.ps1` to generate the base64 encoded pfx contents.  See below.  


## Prerequisites

1. ADL Store account must be created first for spark and base HDI clusters (kafka and `hdi-standalone` should never need ADLS)


## Assumptions

* there is no ScriptAction built into the templates
* no edge nodes
* always 2 headnodes
* default storage is ALWAYS a NEW storage acct b/c the "default" storage can't be shared by multiple clusters concurrently

## Testing

Please see `test.sh` for some general scripts

## ADLS wireup and parameters

* You will need to have an EXISTING
  * SPI
  * cert.  The cert must use a password
  * AAD Application ID
* this does not necessarily need to be stored in keyvault. 
* You must pass this into the ARM template as parameters.  Specifically, the cert must be Base64 encoded and it must be saved as a "secret" not as a cert.  

**Very Important**

* The cert, specifically, must be the Base64 encoded version of the **password-protected** PFX file
* It must have a password
* If you upload the pfx to keyvault and try to download it note that the downloaded pfx file will **not be password-protected**.  
* You will need to apply the password to the pfx file and generate a new pfx file, converted to Base64 encoding, so that you can pass it into the ARM template as a securestring.

**Azure Key Vault and Base64 encoded, password-protected certs**

Azure Key Vault password-protected certificates cannot be downloaded directly.  Instead, you can download the pfx *without* the password-protection.  This throws the error noted below if you attempt to use the pfx for HDI/ADLS.  

The following is the *best way* to ensure you have a cert/password that is compatible with HDI/ADLS.  

* generate the SPI, cert, and AAD Application ID.  
* convert the certificate to Base64.  
  * [base64_helper.ps1](base64_helper.ps1) will convert a password-protected cert to its Base64 version while maintaining the password. 
* create a new Key Vault "secret", not a "certificate", and store the Base64 text value of the pfx in that secret.  
* create a new Key Vault "secret" and store the cert password
* The HDI ARM template will pull the cert and password values which can be used.  

**This is the ONLY way a SPI with certificate password will work with ADLS wireup**

Please see [test.sh](test.sh) for some examples.  

If the pfx and password do not match you will see the following error from the ARM template:

`DeploymentDocument 'AmbariConfiguration_1_7' failed the validation. Error: 'Service Principal Details are invalid - The specified network password is not correct`

This means at some point the pfx file's thumbprint is not available using the supplied password.  
