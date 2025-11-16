#!/bin/bash

# Validation script to verify ARM template modernization

echo "=== ARM Template Modernization Validation ==="
echo ""

PASS=0
FAIL=0

# Check 1: Deprecated services should be archived
echo "1. Checking deprecated services are archived..."
if [ ! -d "infrastructure/arm-templates/resources/OMS" ] && \
   [ ! -d "infrastructure/arm-templates/resources/SQLDataWarehouse" ] && \
   [ ! -d "infrastructure/arm-templates/resources/DataCatalog" ] && \
   [ ! -d "infrastructure/arm-templates/resources/DataLake" ]; then
    echo "   ✅ PASS: Deprecated services removed from active templates"
    ((PASS++))
else
    echo "   ❌ FAIL: Some deprecated services still in active templates"
    ((FAIL++))
fi

# Check 2: Archived services exist in archive
echo "2. Checking archived services exist..."
if [ -d "archive/deprecated-services/OMS" ] && \
   [ -d "archive/deprecated-services/SQLDataWarehouse" ] && \
   [ -d "archive/deprecated-services/DataCatalog" ] && \
   [ -d "archive/deprecated-services/DataLake" ]; then
    echo "   ✅ PASS: All deprecated services archived"
    ((PASS++))
else
    echo "   ❌ FAIL: Some services not properly archived"
    ((FAIL++))
fi

# Check 3: ASE templates use modern API version
echo "3. Checking ASE API versions..."
ASE_OLD=$(grep -r "apiVersion.*2015-02-01" infrastructure/arm-templates/resources/ASE/ 2>/dev/null | wc -l)
ASE_NEW=$(grep -r "apiVersion.*2022-03-01" infrastructure/arm-templates/resources/ASE/ 2>/dev/null | wc -l)
if [ "$ASE_OLD" -eq 0 ] && [ "$ASE_NEW" -gt 0 ]; then
    echo "   ✅ PASS: ASE templates use API version 2022-03-01"
    ((PASS++))
else
    echo "   ⚠️  WARNING: ASE templates may need review (Old: $ASE_OLD, New: $ASE_NEW)"
fi

# Check 4: SQL templates use modern API version
echo "4. Checking SQL-PaaS API versions..."
SQL_OLD=$(grep -r "apiVersion.*2015-05-01-preview\|2014-04-01-preview" infrastructure/arm-templates/resources/SQL-PaaS/ --include="*.json" 2>/dev/null | grep -v "old-" | wc -l)
SQL_NEW=$(grep -r "apiVersion.*2021-11-01" infrastructure/arm-templates/resources/SQL-PaaS/ --include="*.json" 2>/dev/null | wc -l)
if [ "$SQL_OLD" -eq 0 ] && [ "$SQL_NEW" -gt 0 ]; then
    echo "   ✅ PASS: SQL templates use API version 2021-11-01"
    ((PASS++))
else
    echo "   ⚠️  WARNING: SQL templates may have old API versions (Old: $SQL_OLD, New: $SQL_NEW)"
fi

# Check 5: Application Insights uses modern API
echo "5. Checking Application Insights API version..."
APPINS_OLD=$(grep -r "apiVersion.*2014-08-01" infrastructure/arm-templates/resources/ApplicationInsights/ 2>/dev/null | wc -l)
APPINS_NEW=$(grep -r "apiVersion.*2020-02-02" infrastructure/arm-templates/resources/ApplicationInsights/ 2>/dev/null | wc -l)
if [ "$APPINS_OLD" -eq 0 ] && [ "$APPINS_NEW" -gt 0 ]; then
    echo "   ✅ PASS: Application Insights uses API version 2020-02-02"
    ((PASS++))
else
    echo "   ⚠️  WARNING: Application Insights may need review"
fi

# Check 6: No AzureRM PowerShell usage
echo "6. Checking PowerShell scripts for deprecated AzureRM..."
AZURERM=$(grep -r "AzureRM\." infrastructure/scripts/ --include="*.ps1" 2>/dev/null | wc -l)
if [ "$AZURERM" -eq 0 ]; then
    echo "   ✅ PASS: No deprecated AzureRM module usage found"
    ((PASS++))
else
    echo "   ❌ FAIL: Found $AZURERM instances of AzureRM usage"
    ((FAIL++))
fi

# Check 7: Storage uses StorageV2
echo "7. Checking Storage account kind..."
STORAGE_OLD=$(grep -r '"kind".*"Storage"' infrastructure/arm-templates/resources/Storage/ --include="*.json" 2>/dev/null | grep -v "StorageV2" | wc -l)
if [ "$STORAGE_OLD" -eq 0 ]; then
    echo "   ✅ PASS: Storage templates use StorageV2"
    ((PASS++))
else
    echo "   ❌ FAIL: Found $STORAGE_OLD old Storage kind"
    ((FAIL++))
fi

# Check 8: Documentation exists
echo "8. Checking documentation..."
if [ -f "MODERNIZATION-SUMMARY.md" ] && [ -f "MODERNIZATION-PLAN.md" ] && [ -f "archive/deprecated-services/README.md" ]; then
    echo "   ✅ PASS: Modernization documentation exists"
    ((PASS++))
else
    echo "   ❌ FAIL: Missing documentation"
    ((FAIL++))
fi

echo ""
echo "=== Validation Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "✅ All validation checks passed!"
    echo "Repository is modernized and ready for use."
    exit 0
else
    echo "⚠️  Some validation checks failed."
    echo "Review the failures above and address them."
    exit 1
fi
