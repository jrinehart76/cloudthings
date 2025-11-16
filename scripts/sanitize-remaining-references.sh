#!/bin/bash

# Sanitize remaining customer references in the repository
# This script removes MSP/ManagedServiceProvider references and customer-specific data

set -e

echo "🔍 Sanitizing remaining customer references..."
echo ""

# Function to sanitize a file
sanitize_file() {
    local file="$1"
    echo "  Sanitizing: $file"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Replace MSP references
    sed -i '' 's/MSP-/PLATFORM-/g' "$file"
    sed -i '' 's/"MSP/"PLATFORM/g' "$file"
    sed -i '' 's/MSP /PLATFORM /g' "$file"
    sed -i '' 's/msp-/platform-/g' "$file"
    sed -i '' 's/mspplatformautoscripts/platformautoscripts/g' "$file"
    sed -i '' 's/mspautomationscriptsa/platformautomationsa/g' "$file"
    
    # Replace ManagedServiceProvider references
    sed -i '' 's/ManagedServiceProvider/CloudPlatformProvider/g' "$file"
    
    # Replace email addresses
    sed -i '' 's/supportalerts@msp\.com/alerts@example.com/g' "$file"
    
    # Replace Customer-A references
    sed -i '' 's/Customer-A/Customer-Example/g' "$file"
    sed -i '' 's/customer-a/customer-example/g' "$file"
    
    # Check if file actually changed
    if diff -q "$file" "$file.bak" > /dev/null 2>&1; then
        rm "$file.bak"
    else
        echo "    ✓ Updated"
        rm "$file.bak"
    fi
}

# Sanitize alert schema files
echo "📋 Alert Schema Files:"
for file in infrastructure/arm-templates/alertschema/*.json; do
    if [ -f "$file" ]; then
        sanitize_file "$file"
    fi
done

# Sanitize update manager files
echo ""
echo "🔄 Update Manager Files:"
for file in infrastructure/arm-templates/updatemanager/Compliance/Templates/*.json \
            infrastructure/arm-templates/updatemanager/Compliance/Scripts/*.ps1; do
    if [ -f "$file" ]; then
        sanitize_file "$file"
    fi
done

# Sanitize automation scripts
echo ""
echo "⚙️  Automation Scripts:"
for file in infrastructure/arm-templates/automationscripts/*.ps1; do
    if [ -f "$file" ]; then
        sanitize_file "$file"
    fi
done

# Sanitize platform tools
echo ""
echo "🛠️  Platform Tools:"
for file in infrastructure/arm-templates/platformtools/Infrastructure/*.json \
            infrastructure/arm-templates/platformtools/Infrastructure/*.ps1; do
    if [ -f "$file" ]; then
        sanitize_file "$file"
    fi
done

# Sanitize customer-specific alerts
echo ""
echo "🚨 Customer Alerts:"
if [ -d "infrastructure/arm-templates/platformtools/customer-a-alerts" ]; then
    for file in infrastructure/arm-templates/platformtools/customer-a-alerts/*.json; do
        if [ -f "$file" ]; then
            sanitize_file "$file"
        fi
    done
fi

echo ""
echo "✅ Sanitization complete!"
echo ""
echo "📊 Summary:"
echo "  - MSP → PLATFORM"
echo "  - ManagedServiceProvider → CloudPlatformProvider"
echo "  - supportalerts@msp.com → alerts@example.com"
echo "  - Customer-A → Customer-Example"
echo ""
echo "🔍 Verify changes with: git diff"
