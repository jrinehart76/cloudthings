#!/bin/bash

# Script to update SQL-PaaS templates to modern API versions
# This updates deprecated API versions to current stable versions

echo "=== Updating SQL-PaaS API Versions ==="
echo ""

SQL_DIR="infrastructure/arm-templates/resources/SQL-PaaS"

# Backup old templates
echo "1. Archiving old SQL templates..."
mkdir -p archive/old-api-versions/SQL-PaaS
cp "$SQL_DIR/old-SQLServerAndDB.json" archive/old-api-versions/SQL-PaaS/ 2>/dev/null || true
cp "$SQL_DIR/old-SQLServerAndDB.parameters.json" archive/old-api-versions/SQL-PaaS/ 2>/dev/null || true

# Update API versions in all SQL-PaaS templates
echo "2. Updating API versions..."

# Microsoft.Sql/servers: 2015-05-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2015-05-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/databases: 2017-10-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2017-10-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/securityAlertPolicies: 2017-03-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2017-03-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/administrators: 2014-04-01-Preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2014-04-01-Preview"/"apiVersion": "2021-11-01"/g' {} \;
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2014-04-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/firewallRules: 2014-04-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2014-04-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/vulnerabilityAssessments: 2018-06-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2018-06-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Microsoft.Sql/servers/auditingSettings: 2017-05-01-preview → 2021-11-01
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's/"apiVersion": "2017-05-01-preview"/"apiVersion": "2021-11-01"/g' {} \;

# Update schema versions
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" -exec sed -i '' \
    's|http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json|https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json|g' {} \;

echo "3. Updated files:"
find "$SQL_DIR" -name "*.json" -type f ! -name "old-*" ! -name "*.parameters.json"

echo ""
echo "=== API Version Update Complete ==="
echo ""
echo "Summary:"
echo "  - Updated Microsoft.Sql/servers: 2015-05-01-preview → 2021-11-01"
echo "  - Updated Microsoft.Sql/servers/databases: 2017-10-01-preview → 2021-11-01"
echo "  - Updated Microsoft.Sql/servers/securityAlertPolicies: 2017-03-01-preview → 2021-11-01"
echo "  - Updated Microsoft.Sql/servers/administrators: 2014-04-01-preview → 2021-11-01"
echo "  - Updated schema to 2019-04-01"
echo ""
echo "Old templates archived to: archive/old-api-versions/SQL-PaaS/"
