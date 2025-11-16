# Azure ARM Template Modernization Plan

## Executive Summary

This repository contains ARM templates and PowerShell scripts that need modernization to remove deprecated Azure services and update to current resource types and API versions.

**Status:** Ready for modernization
**Last Updated:** 2025-11-15

---

## Deprecated Resources Found

### HIGH PRIORITY - Remove/Archive (Services Retired or Deprecated)

#### 1. OMS (Operations Management Suite) ❌
- **Location:** `infrastructure/arm-templates/resources/OMS/`
- **Status:** DEPRECATED - OMS branding retired in 2019
- **Action:** Archive directory - functionality replaced by Log Analytics Workspace
- **Replacement:** `Microsoft.OperationalInsights/workspaces`
- **Impact:** 5 template files

#### 2. SQL Data Warehouse ❌
- **Location:** `infrastructure/arm-templates/resources/SQLDataWarehouse/`
- **Status:** DEPRECATED - Replaced by Azure Synapse Analytics
- **Action:** Archive directory
- **Replacement:** `Microsoft.Synapse/workspaces` and `Microsoft.Synapse/workspaces/sqlPools`
- **Impact:** 2 template files

#### 3. Data Catalog ❌
- **Location:** `infrastructure/arm-templates/resources/DataCatalog/`
- **Status:** DEPRECATED - Replaced by Microsoft Purview
- **Action:** Archive directory
- **Replacement:** Microsoft Purview Data Catalog
- **Impact:** 1 template file

#### 4. Data Lake Storage Gen1 ⚠️
- **Location:** `infrastructure/arm-templates/resources/DataLake/`
- **Status:** DEPRECATED - Retirement announced, migrate to Gen2
- **Action:** Archive directory
- **Replacement:** Storage Account with `hierarchicalNamespace: true`
- **Impact:** 3 template files (ADLS.json, ADLA.json, ADLS_managedKey.json)

---

### MEDIUM PRIORITY - Update (Deprecation Announced)

#### 5. App Service Environment (ASE) ⚠️
- **Location:** `infrastructure/arm-templates/resources/ASE/`
- **Status:** ASEv2 deprecated (August 2024), ASEv1 retired
- **Action:** Update templates to ASEv3
- **Changes Required:**
  - Update API version to `2022-03-01` or later
  - Update `kind` property to `ASEV3`
  - Update networking configuration for ASEv3
  - Remove deprecated properties
- **Impact:** Multiple template files in ASE directory

#### 6. Old API Versions
- **Location:** Various SQL-PaaS templates
- **Status:** Using API versions from 2015-2017
- **Action:** Update to 2020 or later
- **Files Affected:**
  - `SQL-PaaS/old-SQLServerAndDB.json` (2015-05-01-preview, 2014-04-01-preview)
  - `SQL-PaaS/SQLServerMI.json` (2017-10-01, 2017-05-10)
  - `SQL-PaaS/*Hivemetastore.json` files (2015-05-01-preview, 2017-*)
- **Recommended API Version:** `2021-11-01` or later

#### 7. Storage Account Kind
- **Location:** `infrastructure/arm-templates/resources/Storage/`
- **Status:** Old storage account kind "Storage"
- **Action:** Update to "StorageV2"
- **Changes Required:**
  - Update `kind` from `Storage` to `StorageV2`
  - Add `minimumTlsVersion: TLS1_2`
  - Enable `supportsHttpsTrafficOnly: true`

---

### LOW PRIORITY - Consider Modernization

#### 8. HDInsight ℹ️
- **Location:** `infrastructure/arm-templates/resources/HDInsight/`
- **Status:** Still supported but modern alternatives available
- **Action:** Keep but add note about alternatives
- **Alternatives:** Azure Synapse Spark Pools, Azure Databricks
- **Note:** HDInsight is still fully supported, but for new workloads consider Synapse or Databricks

#### 9. Machine Learning Workbench ⚠️
- **Location:** `infrastructure/arm-templates/resources/MachineLearning/`
- **Status:** ML Workbench deprecated, ML Workspace is current
- **Action:** Review and update to ensure using `Microsoft.MachineLearningServices/workspaces`
- **Files:** MLWorkbench.json, MLWorkspace.json

#### 10. Application Insights
- **Location:** `infrastructure/arm-templates/resources/ApplicationInsights/`
- **Status:** Classic Application Insights deprecated
- **Action:** Update to workspace-based Application Insights
- **Changes Required:**
  - Add `WorkspaceResourceId` property
  - Update API version to `2020-02-02` or later

---

## PowerShell Scripts Status

### ✅ GOOD NEWS - Already Modernized!

All PowerShell scripts are already using the modern **Az module** (not deprecated AzureRM).

**Verified:**
- No `AzureRM.*` cmdlets found
- No `Login-AzureRmAccount` or `Add-AzureAccount` found
- All scripts use `Get-AzVM`, `Get-AzSubscription`, `Set-AzContext`, etc.

**No PowerShell updates required!**

---

## Implementation Plan

### Phase 1: Archive Deprecated Services (Immediate)
1. Create `archive/deprecated-services/` directory
2. Move deprecated directories:
   - `OMS/` → `archive/deprecated-services/OMS/`
   - `SQLDataWarehouse/` → `archive/deprecated-services/SQLDataWarehouse/`
   - `DataCatalog/` → `archive/deprecated-services/DataCatalog/`
   - `DataLake/` → `archive/deprecated-services/DataLake/`
3. Add README in archive explaining why these were deprecated

### Phase 2: Update ASE Templates (High Priority)
1. Review ASE templates for ASEv1/v2 usage
2. Update to ASEv3:
   - API version: `2022-03-01` or later
   - Kind: `ASEV3`
   - Update networking properties
3. Test template validation

### Phase 3: Update API Versions (Medium Priority)
1. Update SQL-PaaS templates to API version `2021-11-01` or later
2. Update Storage templates to use `StorageV2`
3. Update Application Insights to workspace-based
4. Update Machine Learning templates

### Phase 4: Documentation (Low Priority)
1. Add deprecation notices to README files
2. Update REPOSITORY-STATUS.md
3. Create migration guides for deprecated services

---

## Files to Archive

```
infrastructure/arm-templates/resources/OMS/
├── AzureIaasBackup/azuredeploy.json
├── nestedtemplates/omsWorkspace.json
├── nestedtemplates/omsRecoveryServices.json
├── nestedtemplates/omsAutomation.json
├── nestedtemplates/omsAutomation2.json
├── OMS.json
└── OMS.parameters.json

infrastructure/arm-templates/resources/SQLDataWarehouse/
├── ASQLDW.json
├── SQLServer.json
└── README.md

infrastructure/arm-templates/resources/DataCatalog/
└── DataCatalog.json

infrastructure/arm-templates/resources/DataLake/
├── ADLS.json
├── ADLA.json
├── ADLS_managedKey.json
└── README.md
```

---

## Testing Checklist

After modernization:

- [ ] Validate all JSON templates with `az deployment group validate`
- [ ] Check API versions are 2020 or later
- [ ] Verify no deprecated resource types remain
- [ ] Test PowerShell scripts (already using Az module)
- [ ] Update documentation
- [ ] Run git diff to review all changes

---

## Benefits of Modernization

1. **Security:** Newer API versions include latest security features
2. **Support:** Deprecated services may lose support
3. **Features:** Access to latest Azure capabilities
4. **Performance:** Newer services often have better performance
5. **Cost:** Modern services may have better pricing models

---

## Next Steps

1. Review and approve this plan
2. Execute Phase 1 (archive deprecated services)
3. Execute Phase 2 (update ASE templates)
4. Execute Phase 3 (update API versions)
5. Test and validate changes
6. Commit and document

---

**Ready to proceed with modernization!**
