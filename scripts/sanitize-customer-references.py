#!/usr/bin/env python3
"""
Sanitize Customer References Script

This script replaces all customer-specific references with generic placeholders
to prepare the repository for public release.

Author: Jason Rinehart
Usage: python3 scripts/sanitize-customer-references.py [--dry-run]
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple

# Define customer reference mappings
REPLACEMENTS = {
    # Company names (case-insensitive)
    r'\b10th\s+Magnitude\b': 'ManagedServiceProvider',
    r'\b10M\b': 'MSP',
    r'\b10m\b': 'msp',
    
    # Customer A (Estee Lauder / ELC)
    r'\bEstee\s+Lauder\b': 'Customer-A',
    r'\bEsteeCloud\b': 'CustomerA-Cloud',
    r'\bELC\b': 'CUST-A',
    r'\belc-': 'cust-a-',
    
    # Customer B (Helmerich & Payne / H&P)
    r'\bHelmerich\s+&\s+Payne\b': 'Customer-B',
    r'\bHelmerich\s+and\s+Payne\b': 'Customer-B',
    r'\bH&P\b': 'CUST-B',
    r'\bhp-': 'cust-b-',
    
    # Customer C (Children's Mercy / CMH)
    r"\bChildren's\s+Mercy\b": 'Customer-C',
    r'\bCMH\b': 'CUST-C',
    r'\bcmh-': 'cust-c-',
    
    # Generic patterns that might contain customer info
    r'\bpgo-': 'app-',  # Project-specific prefix
}

# File extensions to process
TEXT_EXTENSIONS = {
    '.md', '.txt', '.json', '.ps1', '.sh', '.py', '.js', '.ts',
    '.yaml', '.yml', '.xml', '.html', '.css', '.sql', '.kql',
    '.bicep', '.tf', '.hcl', '.ini', '.conf', '.config'
}

# Directories to skip
SKIP_DIRS = {'.git', 'node_modules', '.vscode', '.idea', '__pycache__'}


def is_text_file(file_path: Path) -> bool:
    """Check if file is a text file we should process."""
    if file_path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    
    # Check if file has no extension but is text
    if not file_path.suffix:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                f.read(1024)  # Try to read first 1KB
            return True
        except (UnicodeDecodeError, PermissionError):
            return False
    
    return False


def sanitize_content(content: str) -> Tuple[str, int]:
    """
    Sanitize content by replacing customer references.
    Returns (sanitized_content, replacement_count)
    """
    sanitized = content
    total_replacements = 0
    
    for pattern, replacement in REPLACEMENTS.items():
        # Use case-insensitive matching
        matches = len(re.findall(pattern, sanitized, re.IGNORECASE))
        if matches > 0:
            sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)
            total_replacements += matches
    
    return sanitized, total_replacements


def sanitize_file(file_path: Path, dry_run: bool = False) -> Tuple[bool, int]:
    """
    Sanitize a single file.
    Returns (was_modified, replacement_count)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
    except (UnicodeDecodeError, PermissionError) as e:
        print(f"  ⚠️  Skipped (read error): {file_path}")
        return False, 0
    
    sanitized_content, replacement_count = sanitize_content(original_content)
    
    if sanitized_content != original_content:
        if not dry_run:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(sanitized_content)
                print(f"  ✓ Sanitized ({replacement_count} replacements): {file_path}")
            except PermissionError:
                print(f"  ⚠️  Skipped (write error): {file_path}")
                return False, 0
        else:
            print(f"  ✓ Would sanitize ({replacement_count} replacements): {file_path}")
        return True, replacement_count
    
    return False, 0


def find_files_to_sanitize(root_dir: Path) -> List[Path]:
    """Find all text files that should be sanitized."""
    files_to_process = []
    
    for root, dirs, files in os.walk(root_dir):
        # Skip excluded directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        
        for file in files:
            file_path = Path(root) / file
            if is_text_file(file_path):
                files_to_process.append(file_path)
    
    return files_to_process


def main():
    parser = argparse.ArgumentParser(
        description='Sanitize customer references in repository'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without making changes'
    )
    args = parser.parse_args()
    
    print("=" * 60)
    print("Repository Sanitization Script")
    print("=" * 60)
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be modified")
    else:
        print("⚠️  WARNING: This will modify files in place!")
        response = input("Have you backed up your repository? (yes/no): ")
        if response.lower() != 'yes':
            print("Please backup your repository first!")
            sys.exit(1)
    
    print()
    print("Customer references to be replaced:")
    for pattern, replacement in REPLACEMENTS.items():
        print(f"  {pattern} → {replacement}")
    print()
    
    # Find files to process
    root_dir = Path.cwd()
    print(f"Scanning repository: {root_dir}")
    files_to_process = find_files_to_sanitize(root_dir)
    print(f"Found {len(files_to_process)} text files to scan")
    print()
    
    # Process files
    modified_count = 0
    total_replacements = 0
    
    for file_path in files_to_process:
        was_modified, replacement_count = sanitize_file(file_path, args.dry_run)
        if was_modified:
            modified_count += 1
            total_replacements += replacement_count
    
    # Summary
    print()
    print("=" * 60)
    print("Sanitization Complete")
    print("=" * 60)
    print(f"Files scanned: {len(files_to_process)}")
    print(f"Files modified: {modified_count}")
    print(f"Total replacements: {total_replacements}")
    print()
    
    if args.dry_run:
        print("This was a DRY RUN. No files were actually modified.")
        print("Run without --dry-run to apply changes.")
    else:
        print("Next steps:")
        print("1. Review changes: git diff")
        print("2. Test that nothing is broken")
        print("3. Commit: git add -A && git commit -m 'Sanitize customer references'")
        print("4. Push: git push")
    
    print()
    print("IMPORTANT: Review the changes carefully before committing!")
    print("=" * 60)


if __name__ == '__main__':
    main()
