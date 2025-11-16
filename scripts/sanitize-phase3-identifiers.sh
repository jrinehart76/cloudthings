#!/bin/bash

# Phase 3 Sanitization - Azure Identifiers
# Sanitize all Azure-specific identifiers: subscription IDs, tenant IDs, resource groups, etc.

set -e

echo "========================================="
echo "Phase 3: Azure Identifier Sanitization"
echo "========================================="
echo ""

# Find all relevant files
FILES=$(find . -type f \
    -not -path "*/\.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/\.kiro/*" \
    -not -path "*/archive/*" \
    -not -path "*/scripts/sanitize-*" \
    \( -name "*.json" -o -name "*.ps1" -o -name "*.sh" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" \))

echo "Sanitizing Azure identifiers..."
echo "-------------------------------------------"

for file in $FILES; do
    if [ -f "$file" ]; then
        # Subscription IDs - replace with placeholder GUIDs
        sed -i '' 's/0ffde392-0ea6-4c28-b315-92e6417ab377/00000000-1111-2222-3333-000000000001/g' "$file" 2>/dev/null || true
        sed -i '' 's/f57996ce-6cfe-400a-a311-f797fd8484d8/00000000-1111-2222-3333-000000000002/g' "$file" 2>/dev/null || true
        sed -i '' 's/7ab6c981-15d8-44aa-a555-0f2ca122f747/00000000-1111-2222-3333-000000000003/g' "$file" 2>/dev/null || true
        sed -i '' 's/7db5d31d-9662-466e-abad-1feba79ff2af/00000000-1111-2222-3333-000000000004/g' "$file" 2>/dev/null || true
        sed -i '' 's/81b75e00-dfaa-4c32-9977-6ed2ac7d9933/00000000-1111-2222-3333-000000000005/g' "$file" 2>/dev/null || true
        sed -i '' 's/d3200bfd-11f2-4931-9c24-38fbfe938d72/00000000-1111-2222-3333-000000000006/g' "$file" 2>/dev/null || true
        
        # Tenant IDs
        sed -i '' 's/0c5638da-d686-4d6a-8df4-e0552c70cb17/00000000-0000-0000-0000-tenant000001/g' "$file" 2>/dev/null || true
        
        # Workspace IDs
        sed -i '' 's/9da7ef4b-fda7-4b76-b315-8b056629b7df/00000000-0000-0000-0000-workspace001/g' "$file" 2>/dev/null || true
        sed -i '' 's/9a69c16a-19bc-447c-aac5-19c664091b58/00000000-0000-0000-0000-workspace002/g' "$file" 2>/dev/null || true
        sed -i '' 's/893ceb48-fc56-43df-9a9b-9f8fb4d0b2d0/00000000-0000-0000-0000-workspace003/g' "$file" 2>/dev/null || true
        
        # Alert IDs and correlation IDs - replace with generic patterns
        sed -i '' 's/[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}/00000000-0000-0000-0000-000000000000/g' "$file" 2>/dev/null || true
        
        # Subscription names
        sed -i '' 's/CUST-A-AM-POC-DevOps/subscription-dev-001/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AM-POC/subscription-poc-001/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AM-PROD-PAAS/subscription-prod-001/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AM-PROD/subscription-prod-002/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AM-NONPROD/subscription-nonprod-001/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AP-NONPROD-V2/subscription-nonprod-002/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AP-PROD-V2/subscription-prod-003/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-EU-NONPROD-V2/subscription-nonprod-003/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-PROD-LEARN/subscription-prod-004/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-AM-NONPROD-CORNERSTONE/subscription-nonprod-004/g' "$file" 2>/dev/null || true
        
        # Resource group patterns
        sed -i '' 's/RG-AM-EastUS-/rg-region1-/g' "$file" 2>/dev/null || true
        sed -i '' 's/RG-AP-/rg-region2-/g' "$file" 2>/dev/null || true
        sed -i '' 's/RG-EU-/rg-region3-/g' "$file" 2>/dev/null || true
        sed -i '' 's/rg-am-eastus-/rg-region1-/g' "$file" 2>/dev/null || true
        sed -i '' 's/rg-ap-southeastasia-/rg-region2-/g' "$file" 2>/dev/null || true
        sed -i '' 's/rg-eu-uksouth-/rg-region3-/g' "$file" 2>/dev/null || true
        
        # AD Group names
        sed -i '' 's/U-CUST-A-/U-Customer-/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-CloudOps/Customer-CloudOps/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-CN-CloudOps/Customer-CloudOps/g' "$file" 2>/dev/null || true
        sed -i '' 's/CUST-A-CEPAPAC/Customer-AppTeam/g' "$file" 2>/dev/null || true
        
        # Action group names
        sed -i '' 's/CUST-A-x-ag-/customer-ag-/g' "$file" 2>/dev/null || true
        
        # Passwords and secrets
        sed -i '' 's/CUST-A-hcl-2017/placeholder-password/g' "$file" 2>/dev/null || true
        
        # Specific resource names
        sed -i '' 's/wbrantley-/user-/g' "$file" 2>/dev/null || true
        sed -i '' 's/hdisomuat-ap-southeastasia-cepa/hdi-cluster-001/g' "$file" 2>/dev/null || true
        sed -i '' 's/acrameastusnonprodnoodleai/acr-region1-001/g' "$file" 2>/dev/null || true
        
        # Service principal and support group names
        sed -i '' 's/CUST-A-CloudOps-ManagedServices-G/Customer-Support-Group/g' "$file" 2>/dev/null || true
    fi
done

echo "✓ Azure identifiers sanitized"
echo ""
echo "========================================="
echo "Phase 3 Sanitization Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Stage changes: git add -A"
echo "3. Commit: git commit -m 'Phase 3: Sanitize Azure identifiers'"
echo "4. Push: git push origin main"
echo ""
