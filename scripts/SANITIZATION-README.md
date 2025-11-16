# Repository Sanitization Guide

This guide explains how to sanitize customer references before making the repository public.

## Why Sanitize?

The repository contains references to actual customers and projects:
- **ManagedServiceProvider / MSP** - Managed service provider name
- **Customer-A / CUST-A** - Customer A
- **Customer-B / CUST-B** - Customer B  
- **Customer-C / CUST-C** - Customer C

These need to be replaced with generic placeholders before public release.

## What Gets Replaced

| Original | Replacement | Type |
|----------|-------------|------|
| ManagedServiceProvider | ManagedServiceProvider | Company |
| MSP / MSP | MSP / msp | Company |
| Customer-A | Customer-A | Customer |
| CustomerA-Cloud | CustomerA-Cloud | Project |
| CUST-A | CUST-A | Customer |
| Customer-B | Customer-B | Customer |
| CUST-B | CUST-B | Customer |
| Customer-C | Customer-C | Customer |
| CUST-C | CUST-C | Customer |

## Sanitization Process

### Step 1: Backup Your Repository

```bash
# Create a backup branch
git checkout -b backup-before-sanitization
git push origin backup-before-sanitization

# Return to main
git checkout main
```

### Step 2: Run Dry Run

Test what will be changed without modifying files:

```bash
python3 scripts/sanitize-customer-references.py --dry-run
```

Review the output to see what files will be modified.

### Step 3: Run Sanitization

```bash
python3 scripts/sanitize-customer-references.py
```

When prompted, confirm you've backed up the repository.

### Step 4: Review Changes

```bash
# See all changes
git diff

# See changed files
git status

# Review specific file
git diff path/to/file
```

### Step 5: Test

Verify nothing is broken:

```bash
# Test any scripts that might be affected
# Check that JSON files are still valid
# Verify ARM templates still work
```

### Step 6: Commit and Push

```bash
git add -A
git commit -m "Sanitize customer references for public release

Replaced all customer-specific references with generic placeholders:
- Company names (ManagedServiceProvider → ManagedServiceProvider)
- Customer names (Customer-A → Customer-A, etc.)
- Project prefixes (CUST-A- → cust-a-, cust-b- → cust-b-, etc.)

This prepares the repository for public release while protecting
customer confidentiality."

git push origin main
```

## Files Affected

The script processes all text files including:
- Markdown (`.md`)
- PowerShell (`.ps1`)
- Shell scripts (`.sh`)
- JSON (`.json`)
- YAML (`.yaml`, `.yml`)
- Python (`.py`)
- KQL queries (`.kql`)
- Bicep/Terraform (`.bicep`, `.tf`)
- Configuration files

## Excluded Directories

The following directories are skipped:
- `.git/` - Git metadata
- `node_modules/` - Dependencies
- `.vscode/` - Editor settings
- `__pycache__/` - Python cache

## Manual Review Required

After sanitization, manually review:

1. **README.md** - Ensure no customer names in examples
2. **Blog references** - Check technicalanxiety.com links don't expose customers
3. **Comments** - Review code comments for customer-specific details
4. **File names** - Check if any files are named after customers
5. **Resource names** - Verify ARM template resource names are generic

## Reverting Changes

If you need to revert:

```bash
# Restore from backup branch
git checkout backup-before-sanitization

# Or reset to before sanitization
git reset --hard HEAD~1
```

## Additional Considerations

### Subscription IDs
The script doesn't replace subscription IDs. If these are sensitive, manually replace them:

```bash
# Find subscription IDs
grep -r "subscriptions/" --include="*.json" --include="*.ps1"
```

### Email Addresses
Replace any customer email addresses:

```bash
# Find email addresses
grep -rE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" --include="*.md" --include="*.json"
```

### IP Addresses
Replace any customer-specific IP addresses or network ranges.

## Verification Checklist

Before making repository public:

- [ ] Ran sanitization script
- [ ] Reviewed all changes with `git diff`
- [ ] Tested that scripts still work
- [ ] Manually checked README.md
- [ ] Searched for remaining customer names
- [ ] Verified no sensitive subscription IDs
- [ ] Checked for customer email addresses
- [ ] Reviewed file and directory names
- [ ] Tested ARM template deployments
- [ ] Committed changes with clear message
- [ ] Created backup branch

## Support

If you find customer references that weren't caught by the script:

1. Add the pattern to `REPLACEMENTS` in the Python script
2. Run the script again
3. Update this README with the new pattern

## Script Maintenance

To add new customer references to sanitize:

Edit `scripts/sanitize-customer-references.py`:

```python
REPLACEMENTS = {
    # Add new patterns here
    r'\bNewCustomer\b': 'Customer-D',
    r'\bnew-cust-': 'cust-d-',
}
```

Then run the script again.
