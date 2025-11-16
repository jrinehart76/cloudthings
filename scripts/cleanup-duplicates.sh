#!/bin/bash

# Cleanup Duplicate Content
# Remove infrastructure/source directory which duplicates arm-templates/resources

set -e

echo "========================================="
echo "Cleaning Up Duplicate Content"
echo "========================================="
echo ""

# Verify the duplication
echo "Analyzing directory sizes..."
echo "-------------------------------------------"
SOURCE_SIZE=$(du -sh infrastructure/source 2>/dev/null | awk '{print $1}')
ARM_SIZE=$(du -sh infrastructure/arm-templates/resources 2>/dev/null | awk '{print $1}')

echo "infrastructure/source: $SOURCE_SIZE"
echo "infrastructure/arm-templates/resources: $ARM_SIZE"
echo ""

# Count files
SOURCE_FILES=$(find infrastructure/source -type f 2>/dev/null | wc -l | tr -d ' ')
ARM_FILES=$(find infrastructure/arm-templates/resources -type f 2>/dev/null | wc -l | tr -d ' ')

echo "Files in infrastructure/source: $SOURCE_FILES"
echo "Files in infrastructure/arm-templates/resources: $ARM_FILES"
echo ""

echo "Analysis:"
echo "-------------------------------------------"
echo "The infrastructure/source directory contains:"
echo "  - Duplicate ARM templates (already in arm-templates/resources)"
echo "  - Duplicate scripts (already in infrastructure/scripts)"
echo "  - ACS-engine templates (deprecated, replaced by AKS)"
echo "  - Dashboard templates (already in arm-templates/platformtools)"
echo ""
echo "This directory is redundant and can be safely removed."
echo ""

read -p "Remove infrastructure/source directory? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "Removing infrastructure/source..."
    rm -rf infrastructure/source
    echo "✓ Removed infrastructure/source directory"
    echo ""
    echo "Cleanup complete!"
    echo "Freed up: $SOURCE_SIZE"
    echo "Removed: $SOURCE_FILES files"
else
    echo ""
    echo "Cleanup cancelled."
fi

echo ""
