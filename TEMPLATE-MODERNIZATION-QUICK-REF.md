# ARM Template Modernization - Quick Reference

## What Changed?

### ❌ Removed (Archived)
- **OMS** → Use Log Analytics Workspace
- **SQL Data Warehouse** → Use Azure Synapse Analytics  
- **Data Catalog** → Use Microsoft Purview
- **Data Lake Gen1** → Use Storage Account Gen2
- **ML Workbench** → Use Azure ML Services

### ✅ Updated
- **ASE**: ASEv2 → ASEv3 (API 2022-03-01)
- **SQL-PaaS**: 2015-2017 APIs → 2021-11-01
- **Application Insights**: Classic → Workspace-based (API 2020-02-02)

### ✅ Already Modern
- **PowerShell scripts**: Using Az module
- **Storage**: Using StorageV2
- **Most other templates**: Current API versions

## Quick Commands

### Validate Modernization
```bash
bash scripts/validate-modernization.sh
```

### Analyze Deprecated Resources
```bash
bash scripts/modernize-templates.sh
```

### Test ARM Template
```bash
az deployment group validate \
  --resource-group <rg-name> \
  --template-file <template.json> \
  --parameters <parameters.json>
```

## Migration Paths

| Old Service | New Service | Documentation |
|------------|-------------|---------------|
| OMS | Log Analytics | [Link](https://docs.microsoft.com/azure/azure-monitor/platform/oms-portal-transition) |
| SQL DW | Synapse Analytics | [Link](https://docs.microsoft.com/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-overview-what-is) |
| Data Catalog | Microsoft Purview | [Link](https://docs.microsoft.com/azure/purview/overview) |
| ADLS Gen1 | Storage Gen2 | [Link](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-migrate-gen1-to-gen2) |

## Files to Reference

- **Full Details**: `MODERNIZATION-SUMMARY.md`
- **Planning Doc**: `MODERNIZATION-PLAN.md`
- **Archived Templates**: `archive/deprecated-services/`
- **Validation Script**: `scripts/validate-modernization.sh`

## API Version Reference

| Resource Type | Old API | New API |
|--------------|---------|---------|
| Microsoft.Web/hostingEnvironments | 2015-02-01 | 2022-03-01 |
| Microsoft.Sql/servers | 2015-05-01-preview | 2021-11-01 |
| Microsoft.Sql/servers/databases | 2017-10-01-preview | 2021-11-01 |
| microsoft.insights/components | 2014-08-01 | 2020-02-02 |

## Status Check

Run validation: `bash scripts/validate-modernization.sh`

Expected result: ✅ All validation checks passed!

---

**Last Updated:** 2025-11-15
