# Deprecated Azure Services - Archived Templates

This directory contains ARM templates for Azure services that have been deprecated or retired by Microsoft. These templates are preserved for historical reference but should **NOT** be used for new deployments.

## Archived Services

### OMS (Operations Management Suite)
- **Deprecated:** 2019
- **Status:** Retired - OMS branding discontinued
- **Replacement:** Azure Monitor Log Analytics Workspace (`Microsoft.OperationalInsights/workspaces`)
- **Migration Guide:** https://docs.microsoft.com/azure/azure-monitor/platform/oms-portal-transition

### SQL Data Warehouse
- **Deprecated:** 2020
- **Status:** Replaced by Azure Synapse Analytics
- **Replacement:** `Microsoft.Synapse/workspaces` and `Microsoft.Synapse/workspaces/sqlPools`
- **Migration Guide:** https://docs.microsoft.com/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-overview-what-is

### Data Catalog
- **Deprecated:** 2021
- **Status:** Replaced by Microsoft Purview
- **Replacement:** Microsoft Purview Data Catalog
- **Migration Guide:** https://docs.microsoft.com/azure/purview/overview

### Data Lake Storage Gen1
- **Deprecated:** 2024 (retirement announced)
- **Status:** End of life February 29, 2024
- **Replacement:** Azure Data Lake Storage Gen2 (Storage Account with `hierarchicalNamespace: true`)
- **Migration Guide:** https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-migrate-gen1-to-gen2

## Why These Were Archived

1. **No Longer Supported:** Microsoft has ended support for these services
2. **Security Risks:** Deprecated services don't receive security updates
3. **Missing Features:** Modern replacements have significantly more capabilities
4. **Cost Efficiency:** Newer services often have better pricing models
5. **Best Practices:** Using deprecated services is not recommended for production

## If You Need These Templates

If you absolutely need to reference these templates:

1. **For Migration:** Use these as reference to understand your current infrastructure
2. **For Learning:** Study the differences between old and new services
3. **For Documentation:** Document what was used historically

**DO NOT deploy these templates to production environments!**

## Modern Alternatives

| Deprecated Service | Modern Replacement | Location |
|-------------------|-------------------|----------|
| OMS | Log Analytics Workspace | `infrastructure/log-analytics/` |
| SQL Data Warehouse | Azure Synapse Analytics | Create new Synapse templates |
| Data Catalog | Microsoft Purview | Use Azure Portal or Bicep |
| Data Lake Gen1 | Storage Account Gen2 | `infrastructure/arm-templates/resources/Storage/` |

## Questions?

If you have questions about migrating from these deprecated services, please refer to:
- Microsoft Azure documentation
- Azure migration guides
- Azure support

---

**Last Updated:** 2025-11-15
**Archived By:** Repository modernization process
