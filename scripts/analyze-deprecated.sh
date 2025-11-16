#!/bin/bash

# Analyze ARM templates and scripts for deprecated resources

echo "========================================="
echo "Analyzing for Deprecated Azure Resources"
echo "========================================="
echo ""

echo "Checking for deprecated services..."
echo "-------------------------------------------"

# Check for deprecated services
echo ""
echo "1. OMS (Operations Management Suite) - DEPRECATED"
echo "   Replaced by: Log Analytics Workspace"
OMS_COUNT=$(find infrastructure/arm-templates/resources/OMS -type f 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $OMS_COUNT files in OMS directory"
echo "   Status: OMS branding deprecated, should use Log Analytics"
echo ""

echo "2. HDInsight - CHECK NEEDED"
HDI_COUNT=$(find infrastructure/arm-templates/resources/HDInsight -type f 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $HDI_COUNT files"
echo "   Status: Still supported but consider Azure Synapse Analytics"
echo ""

echo "3. Data Lake Gen1 - DEPRECATED"
ADLS_COUNT=$(grep -r "Microsoft.DataLakeStore" infrastructure/arm-templates/resources/ 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $ADLS_COUNT references"
echo "   Status: Gen1 deprecated, should use Data Lake Gen2 (Storage v2)"
echo ""

echo "4. SQL Data Warehouse - DEPRECATED"
DW_COUNT=$(find infrastructure/arm-templates/resources/SQLDataWarehouse -type f 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $DW_COUNT files"
echo "   Status: Rebranded as Azure Synapse Analytics (dedicated SQL pools)"
echo ""

echo "5. App Service Environment v2 - DEPRECATED"
ASE_COUNT=$(grep -r "Microsoft.Web/hostingEnvironments" infrastructure/arm-templates/resources/ASE 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $ASE_COUNT references"
echo "   Status: ASEv2 deprecated, should use ASEv3"
echo ""

echo "6. Couchbase - THIRD PARTY"
CB_COUNT=$(find infrastructure/arm-templates/resources/Couchbase -type f 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $CB_COUNT files"
echo "   Status: Third-party, consider Azure Cosmos DB"
echo ""

echo ""
echo "========================================="
echo "Recommendations"
echo "========================================="
echo ""
echo "REMOVE (Deprecated):"
echo "  - OMS directory (use Log Analytics instead)"
echo "  - SQLDataWarehouse directory (use Synapse Analytics)"
echo "  - Data Lake Gen1 templates (use Storage v2 with hierarchical namespace)"
echo ""
echo "UPDATE (Still valid but old):"
echo "  - ASE templates to ASEv3"
echo "  - HDInsight templates (verify API versions)"
echo ""
echo "CONSIDER REMOVING (Third-party/Niche):"
echo "  - Couchbase (use Cosmos DB instead)"
echo ""
