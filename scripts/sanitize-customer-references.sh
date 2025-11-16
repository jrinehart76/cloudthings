#!/bin/bash

# Sanitize Customer References Script
# This script replaces all customer-specific references with generic placeholders
# to prepare the repository for public release.

set -e

echo "=========================================="
echo "Repository Sanitization Script"
echo "=========================================="
echo "This will replace customer references with generic placeholders"
echo ""

# Backup warning
read -p "Have you backed up your repository? (yes/no): " backup_confirm
if [ "$backup_confirm" != "yes" ]; then
    echo "Please backup your repository first!"
    exit 1
fi

echo ""
echo "Starting sanitization..."
echo ""

# Define replacements (case-insensitive where appropriate)
declare -A replacements=(
    # Company names
    ["ManagedServiceProvider"]="ManagedServiceProvider"
    ["MSP"]="MSP"
    ["MSP"]="msp"
    
    # Customer names
    ["Customer-A"]="Customer-A"
    ["CustomerA-Cloud"]="CustomerA-Cloud"
    ["CUST-A"]="CUST-A"
    ["Customer-B"]="Customer-B"
    ["Customer-B"]="Customer-B"
    ["CUST-B"]="CUST-B"
    ["Customer-C"]="Customer-C"
    ["CUST-C"]="CUST-C"
    
    # Project/environment names that might be customer-specific
    ["CustomerA-Cloud"]="CustomerCloud"
    ["CUST-A-"]="cust-a-"
    ["cust-b-"]="cust-b-"
    ["CUST-C-"]="cust-c-"
)

# Function to sanitize a file
sanitize_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    # Skip binary files
    if file "$file" | grep -q "text"; then
        cp "$file" "$temp_file"
        
        # Apply each replacement
        for search in "${!replacements[@]}"; do
            replace="${replacements[$search]}"
            # Use perl for case-insensitive replacement where appropriate
            perl -pi -e "s/\Q$search\E/$replace/gi" "$temp_file"
        done
        
        # Only replace if file changed
        if ! cmp -s "$file" "$temp_file"; then
            mv "$temp_file" "$file"
            echo "  ✓ Sanitized: $file"
            return 0
        else
            rm "$temp_file"
            return 1
        fi
    fi
    return 1
}

# Counter for modified files
modified_count=0

# Find and sanitize all text files (excluding .git directory)
echo "Scanning repository for customer references..."
echo ""

while IFS= read -r -d '' file; do
    if sanitize_file "$file"; then
        ((modified_count++))
    fi
done < <(find . -type f -not -path "./.git/*" -not -path "./node_modules/*" -print0)

echo ""
echo "=========================================="
echo "Sanitization Complete"
echo "=========================================="
echo "Files modified: $modified_count"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test that nothing is broken"
echo "3. Commit changes: git add -A && git commit -m 'Sanitize customer references'"
echo "4. Push to remote: git push"
echo ""
echo "IMPORTANT: Review the changes carefully before committing!"
echo "=========================================="
