#!/bin/bash

# Azure ARM Template Modernization Script
# Identifies deprecated resources and API versions that need updating

echo "=== Azure ARM Template Modernization Analysis ==="
echo ""

# Define deprecated services and their replacements
declare -A DEPRECATED_SERVICES=(
    ["OMS"]="Log Analytics Workspace (Microsoft.OperationalInsights/workspaces)"
    ["SQLDataWarehouse"]="Azure Synapse Analytics (Microsoft.Synapse/workspaces)"
    ["DataLake Gen1"]="Azure Data Lake Storage Gen2 (Storage Account with hierarchicalNamespace)"
    ["ASEv2"]="App Service Environment v3 (Microsoft.Web/hostingEnvironments)"
    ["HDInsight"]="Azure Synapse Spark Pools or Azure Databricks"
    ["Data Catalog"]="Microsoft Purview"
    ["Machine Learning Workbench"]="Azure Machine Learning workspace"
)

echo "1. DEPRECATED SERVICES FOUND:"
echo "=============================="

# Check for OMS (Operations Management Suite) - deprecated, use Log Analytics
if [ -d "infrastructure/arm-templates/resources/OMS" ]; then
    echo "❌ OMS (Operations Management Suite)"
    echo "   Location: infrastructure/arm-templates/resources/OMS/"
    echo "   Status: DEPRECATED - OMS branding retired in 2019"
    echo "   Action: Migrate to Log Analytics Workspace (Microsoft.OperationalInsights/workspaces)"
    echo "   Files:"
    find infrastructure/arm-templates/resources/OMS -name "*.json" | head -5
    echo ""
fi

# Check for SQL Data Warehouse - deprecated, use Synapse
if [ -d "infrastructure/arm-templates/resources/SQLDataWarehouse" ]; then
    echo "❌ SQL Data Warehouse"
    echo "   Location: infrastructure/arm-templates/resources/SQLDataWarehouse/"
    echo "   Status: DEPRECATED - Replaced by Azure Synapse Analytics"
    echo "   Action: Migrate to Microsoft.Synapse/workspaces"
    echo "   Files:"
    find infrastructure/arm-templates/resources/SQLDataWarehouse -name "*.json"
    echo ""
fi

# Check for Data Lake Gen1 - deprecated, use Gen2
if [ -d "infrastructure/arm-templates/resources/DataLake" ]; then
    echo "⚠️  Data Lake Storage Gen1"
    echo "   Location: infrastructure/arm-templates/resources/DataLake/"
    echo "   Status: DEPRECATED - Retirement announced, use Gen2"
    echo "   Action: Migrate to Storage Account with hierarchicalNamespace=true"
    echo "   Files:"
    find infrastructure/arm-templates/resources/DataLake -name "*.json"
    echo ""
fi

# Check for ASE (App Service Environment) - ASEv2 deprecated
if [ -d "infrastructure/arm-templates/resources/ASE" ]; then
    echo "⚠️  App Service Environment"
    echo "   Location: infrastructure/arm-templates/resources/ASE/"
    echo "   Status: ASEv2 DEPRECATED (Aug 2024), ASEv1 retired"
    echo "   Action: Migrate to ASEv3 with updated API version"
    echo "   Files:"
    find infrastructure/arm-templates/resources/ASE -name "*.json" | head -5
    echo ""
fi

# Check for HDInsight - not deprecated but has modern alternatives
if [ -d "infrastructure/arm-templates/resources/HDInsight" ]; then
    echo "⚠️  HDInsight"
    echo "   Location: infrastructure/arm-templates/resources/HDInsight/"
    echo "   Status: Still supported but consider modern alternatives"
    echo "   Action: Consider Azure Synapse Spark Pools or Azure Databricks for new workloads"
    echo "   Files:"
    find infrastructure/arm-templates/resources/HDInsight -name "*.json" | head -5
    echo ""
fi

# Check for Data Catalog - deprecated
if [ -d "infrastructure/arm-templates/resources/DataCatalog" ]; then
    echo "❌ Data Catalog"
    echo "   Location: infrastructure/arm-templates/resources/DataCatalog/"
    echo "   Status: DEPRECATED - Replaced by Microsoft Purview"
    echo "   Action: Migrate to Microsoft Purview"
    echo "   Files:"
    find infrastructure/arm-templates/resources/DataCatalog -name "*.json"
    echo ""
fi

# Check for Machine Learning Workbench - deprecated
if [ -d "infrastructure/arm-templates/resources/MachineLearning" ]; then
    echo "⚠️  Machine Learning"
    echo "   Location: infrastructure/arm-templates/resources/MachineLearning/"
    echo "   Status: ML Workbench DEPRECATED - Use Azure ML workspace"
    echo "   Action: Verify using Microsoft.MachineLearningServices/workspaces"
    echo "   Files:"
    find infrastructure/arm-templates/resources/MachineLearning -name "*.json"
    echo ""
fi

echo ""
echo "2. OLD API VERSIONS:"
echo "===================="

# Check for old API versions (pre-2020)
echo "Checking for API versions older than 2020..."
grep -r "apiVersion.*201[0-9]-" infrastructure/arm-templates/resources/ --include="*.json" | \
    grep -v "2019-" | grep -v "2018-" | head -20

echo ""
echo "3. SPECIFIC DEPRECATED PATTERNS:"
echo "================================="

# Check for classic resources
echo "Classic resources (should use ARM):"
grep -r "Microsoft.ClassicCompute\|Microsoft.ClassicStorage\|Microsoft.ClassicNetwork" \
    infrastructure/arm-templates/ --include="*.json" | head -10

echo ""
echo "Old storage account kinds:"
grep -r '"kind".*"Storage"' infrastructure/arm-templates/resources/Storage/ --include="*.json" | \
    grep -v "StorageV2" | head -10

echo ""
echo "4. RECOMMENDATIONS:"
echo "==================="
echo ""
echo "HIGH PRIORITY (Deprecated/Retired):"
echo "  1. Remove or archive OMS templates - use Log Analytics"
echo "  2. Remove or archive SQL Data Warehouse - use Synapse Analytics"
echo "  3. Remove or archive Data Catalog - use Microsoft Purview"
echo "  4. Update Data Lake Gen1 to Gen2 (Storage Account with hierarchicalNamespace)"
echo ""
echo "MEDIUM PRIORITY (Deprecation Announced):"
echo "  5. Update ASE templates to ASEv3"
echo "  6. Update API versions to 2020 or later"
echo "  7. Update Storage accounts to StorageV2"
echo ""
echo "LOW PRIORITY (Consider Modernization):"
echo "  8. Review HDInsight - consider Synapse or Databricks for new workloads"
echo "  9. Review Machine Learning templates - ensure using latest workspace API"
echo " 10. Update Application Insights to workspace-based"
echo ""
echo "=== Analysis Complete ==="
