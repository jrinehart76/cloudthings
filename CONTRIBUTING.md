# Contributing to Azure Cloud Things

Thank you for your interest in contributing! This repository aims to provide production-ready Azure templates and patterns that help the community solve real-world problems.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest enhancements
- Search existing issues before creating a new one
- Provide clear descriptions with examples
- Include relevant error messages or logs

### Submitting Changes

1. **Fork the repository**

   ```bash
   git clone https://github.com/yourusername/cloudthings.git
   cd cloudthings
   ```

2. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style and patterns
   - Update documentation as needed
   - Test your changes thoroughly

4. **Commit your changes**

   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

5. **Push to your fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Explain the benefit of your contribution

## Contribution Guidelines

### ARM Templates

- Use current API versions (2020 or later preferred)
- Include parameter descriptions
- Follow Azure naming conventions
- Test template validation before submitting
- Include example parameter files

### PowerShell Scripts

- Use the Az module (not deprecated AzureRM)
- Include comment-based help
- Handle errors gracefully
- Use approved verbs (Get-, Set-, New-, etc.)
- Test in PowerShell 7+ when possible

### KQL Queries

- Include comments explaining the query logic
- Optimize for performance
- Test against sample data
- Document expected results
- Include time range considerations

### Documentation

- Use clear, concise language
- Include examples where helpful
- Link to relevant Azure documentation
- Update BLOG-TO-CODE-MAPPING.md if applicable
- Check spelling and grammar

## Code Style

### ARM Template Format

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "parameterName": {
      "type": "string",
      "metadata": {
        "description": "Clear description of parameter"
      }
    }
  }
}
```

### PowerShell Format

```powershell
<#
.SYNOPSIS
    Brief description

.DESCRIPTION
    Detailed description

.PARAMETER ParameterName
    Description of parameter

.EXAMPLE
    Example usage
#>
```

### KQL Format

```kql
// Query description
// Expected result: What this query returns
ResourceType
| where TimeGenerated > ago(24h)
| summarize Count = count() by Property
| order by Count desc
```

## Testing

Before submitting:

- **ARM Templates:** Validate with `az deployment group validate`
- **PowerShell:** Test syntax with `Test-ScriptFileInfo` or manual execution
- **KQL:** Test in Log Analytics workspace
- **JSON:** Validate syntax with `jq` or online validators

## What We're Looking For

### High Priority

- Bug fixes
- Security improvements
- Performance optimizations
- Documentation improvements
- Updated API versions

### Welcome Contributions

- New ARM templates for common scenarios
- Additional KQL queries for monitoring
- Automation runbooks
- Landing zone enhancements
- Real-world examples

### Not Accepting

- Templates for deprecated Azure services
- Code using deprecated APIs without migration path
- Undocumented changes
- Breaking changes without discussion

## Questions?

- Open a GitHub Issue for questions
- Reference blog articles at [technicalanxiety.com](https://technicalanxiety.com)
- Connect on [Twitter](https://twitter.com/anxiouslytech) or [LinkedIn](https://linkedin.com/in/rinehart76)

## Code of Conduct

Be respectful, constructive, and professional. We're all here to learn and help each other.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Azure easier for everyone!
