---
inclusion: fileMatch
fileMatchPattern: "**/*.md"
---

# Documentation Standards

## README Files
- **Purpose-Driven Structure**: Organize content based on specific purpose and context
- **Blog Integration**: Include direct links to blog articles using format: `[Article Title](https://technicalanxiety.com/article-slug/)`
- **Practical Focus**: Emphasize real-world usage and implementation guidance
- **Progressive Complexity**: Start with basic examples, build to advanced scenarios

## Template Usage
- **Bicep Templates**: Use `.kiro/templates/bicep-template-readme.md`
- **PowerShell Scripts**: Use `.kiro/templates/powershell-script-readme.md`
- **Complete Solutions**: Use `.kiro/templates/solution-project-readme.md`

## Content Linking
- Always connect implementations back to blog articles when applicable
- Update BLOG-TO-CODE-MAPPING.md when adding new implementations
- Include context about why specific approaches were chosen
- Reference related implementations within the repository

## Naming Conventions
- **Mixed Approach**: Use descriptive names that reflect purpose
- **Parameter Files**: Match template name with `.parameters.json` suffix
- **Descriptive Resources**: Use clear, business-meaningful resource names
- **Script Organization**: Organize by both technology and function as appropriate

## Versioning
- **File Headers**: Include version information in all templates and scripts
- **Format**: `Version: X.Y.Z - Description of changes`
- **Semantic Versioning**: Major.Minor.Patch format
- **Changelog**: Maintain CHANGELOG.md files for major components

## Security in Examples
- **Environment Variables**: Use `${ENVIRONMENT_VARIABLE}` pattern for sensitive values
- **Parameter References**: Use `@secure()` decorator in Bicep for sensitive parameters
- **Key Vault Integration**: Reference secrets from Azure Key Vault in examples
- **Placeholder Format**: Use `<REPLACE_WITH_YOUR_VALUE>` for required user inputs
- **No Hardcoded Secrets**: Never include actual credentials, keys, or sensitive data