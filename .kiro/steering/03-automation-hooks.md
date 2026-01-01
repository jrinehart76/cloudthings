---
inclusion: manual
---

# Automation Workflows & Agent Hooks Reference

## File Save Automation Triggers

### Bicep Template Automation
When Bicep files are saved:
- Validate template syntax and parameter definitions
- Extract parameter information for documentation tables
- Check for README.md and update parameter documentation
- Suggest blog article connections for new implementations
- Recommend BLOG-TO-CODE-MAPPING.md updates
- Generate .parameters.json files with secure placeholder values

### PowerShell Script Automation  
When PowerShell files are saved:
- Validate syntax and comment-based help completeness
- Check for proper error handling and parameter validation
- Update or create README.md using PowerShell template
- Suggest related blog articles and implementations
- Verify security best practices (no hardcoded secrets)

### Documentation Automation
When README files are saved:
- Validate all internal and external links
- Check template compliance and formatting
- Verify parameter documentation matches actual files
- Suggest missing related resources and cross-references

## Manual Maintenance Operations

### Bulk Documentation Generation
- Scan repository for missing or outdated documentation
- Generate README files for undocumented implementations
- Update parameter tables from actual template definitions
- Create missing parameter files for Bicep templates

### Comprehensive Validation
- Validate all Bicep templates using Azure CLI
- Check PowerShell scripts for syntax and best practices
- Verify parameter file validity and template matching
- Test all documentation links (internal and external)
- Scan for security issues and hardcoded values

### Blog Mapping Maintenance
- Identify new implementations not yet mapped to blog articles
- Suggest connections between Technical Anxiety articles and code
- Review existing mappings for accuracy and completeness
- Validate all blog article links

### Repository Health Monitoring
- Review folder organization and suggest optimizations
- Identify outdated content for archival
- Check version consistency across related components
- Validate cross-references and related resource links
- Assess security practices and compliance