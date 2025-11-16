#!/bin/bash

# Phase 2 Sanitization - Deep Clean
# This script handles additional customer-specific information missed in phase 1

set -e

echo "========================================="
echo "Phase 2: Deep Sanitization"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for changes
TOTAL_CHANGES=0

echo "Step 1: Removing sensitive directories..."
echo "-------------------------------------------"

# Remove the clients/hp directory entirely (contains customer-specific code)
if [ -d "clients/hp" ]; then
    echo -e "${YELLOW}Removing clients/hp directory...${NC}"
    rm -rf clients/hp
    echo -e "${GREEN}✓ Removed clients/hp${NC}"
    ((TOTAL_CHANGES++))
fi

# Remove infrastructure/source/H&P directory
if [ -d "infrastructure/source/H&P" ]; then
    echo -e "${YELLOW}Removing infrastructure/source/H&P directory...${NC}"
    rm -rf "infrastructure/source/H&P"
    echo -e "${GREEN}✓ Removed infrastructure/source/H&P${NC}"
    ((TOTAL_CHANGES++))
fi

echo ""
echo "Step 2: Sanitizing domain names and URLs..."
echo "-------------------------------------------"

# Find all text files (excluding .git, node_modules, etc.)
FILES=$(find . -type f \
    -not -path "*/\.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/\.kiro/*" \
    -not -path "*/archive/*" \
    \( -name "*.json" -o -name "*.ps1" -o -name "*.sh" -o -name "*.conf" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.txt" \))

for file in $FILES; do
    if [ -f "$file" ]; then
        # Domain names
        sed -i '' 's/customer-a-domain\.net/customer-a-domain.local/g' "$file" 2>/dev/null || true
        sed -i '' 's/estee\.com/customer-a.com/g' "$file" 2>/dev/null || true
        sed -i '' 's/esteelaudercn\.partner\.onmschina\.cn/customer-a-cn.partner.onmschina.cn/g' "$file" 2>/dev/null || true
        
        # Azure DevOps URLs
        sed -i '' 's/client-customer-b/client-customer-b/g' "$file" 2>/dev/null || true
        
        # Email addresses
        sed -i '' 's/@10thmagnitude\.com/@msp.com/g' "$file" 2>/dev/null || true
        sed -i '' 's/@estee\.com/@customer-a.com/g' "$file" 2>/dev/null || true
        sed -i '' 's/admin@/admin@/g' "$file" 2>/dev/null || true
        sed -i '' 's/devuser@/devuser@/g' "$file" 2>/dev/null || true
        sed -i '' 's/devuser@/devuser@/g' "$file" 2>/dev/null || true
        sed -i '' 's/admin@/admin@/g' "$file" 2>/dev/null || true
        sed -i '' 's/admin@/admin@/g' "$file" 2>/dev/null || true
        
        # Internal server names
        sed -i '' 's/us-smy-dc[0-9][0-9]/dc-server/g' "$file" 2>/dev/null || true
        sed -i '' 's/us-tht-dc[0-9][0-9]/dc-server/g' "$file" 2>/dev/null || true
        sed -i '' 's/us-smy-nas[0-9]/nas-server/g' "$file" 2>/dev/null || true
        sed -i '' 's/us-tht-nas[0-9]/nas-server/g' "$file" 2>/dev/null || true
        sed -i '' 's/us-azr-sapadm[0-9][0-9]/sap-admin-server/g' "$file" 2>/dev/null || true
        
        # Proxy servers
        sed -i '' 's/elcproxy\.customer-a-domain\.net/proxy.customer-a-domain.local/g' "$file" 2>/dev/null || true
        
        # Mail relays
        sed -i '' 's/mailrelay\.am\.customer-a-domain\.net/mailrelay.customer-a-domain.local/g' "$file" 2>/dev/null || true
        
        # Storage account names with customer references
        sed -i '' 's/mspplatformautoscripts/mspplatformautoscripts/g' "$file" 2>/dev/null || true
        sed -i '' 's/mspautomationscriptsa/mspautomationscriptsa/g' "$file" 2>/dev/null || true
        
        # Action group short names
        sed -i '' 's/"MSP/"MSP/g' "$file" 2>/dev/null || true
        
        # Certificate and secret names
        sed -i '' 's/custa-msp-HdiTemplate/custa-msp-HdiTemplate/g' "$file" 2>/dev/null || true
        
        # Diagnostic settings
        sed -i '' 's/mspdiagnostic/mspdiagnostic/g' "$file" 2>/dev/null || true
        sed -i '' 's/MSPDiagnostic/MSPDiagnostic/g' "$file" 2>/dev/null || true
        
        # Tags
        sed -i '' 's/MSPMonitored/MSPMonitored/g' "$file" 2>/dev/null || true
        
        # Okta URLs
        sed -i '' 's/customer-a-domain\.okta/customer-a.okta/g' "$file" 2>/dev/null || true
        sed -i '' 's/customer-a-domain\.oktapreview/customer-a.oktapreview/g' "$file" 2>/dev/null || true
        sed -i '' 's/customer-a-confluence/customer-a-confluence/g' "$file" 2>/dev/null || true
    fi
done

echo -e "${GREEN}✓ Sanitized domain names and URLs${NC}"
((TOTAL_CHANGES++))

echo ""
echo "Step 3: Removing sensitive files..."
echo "-------------------------------------------"

# Remove LastPass file with passwords
if [ -f "clients/hp/scripts/lastpass.rtf" ]; then
    echo -e "${YELLOW}Removing LastPass file with credentials...${NC}"
    rm -f "clients/hp/scripts/lastpass.rtf"
    echo -e "${GREEN}✓ Removed lastpass.rtf${NC}"
    ((TOTAL_CHANGES++))
fi

echo ""
echo "========================================="
echo "Phase 2 Sanitization Complete!"
echo "========================================="
echo ""
echo -e "${GREEN}Total changes: $TOTAL_CHANGES${NC}"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Stage changes: git add -A"
echo "3. Commit: git commit -m 'Phase 2: Deep sanitization of customer data'"
echo "4. Push: git push origin main"
echo ""
