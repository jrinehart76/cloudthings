# [Script Name]

## Overview

Brief description of what this PowerShell script does and its primary use case.

**Blog Article:** [Article Title](https://technicalanxiety.com/article-slug/)

## Purpose

Detailed explanation of:
- What problem this script solves
- When to use it
- Expected outcomes

## Prerequisites

- PowerShell 7.0+ (or 5.1 minimum)
- Azure PowerShell Az module
- Required Azure permissions:
  - [Permission 1]
  - [Permission 2]
- [Other dependencies]

## Parameters

| Parameter | Type | Required | Description | Default |
|-----------|------|----------|-------------|---------|
| `ParameterName` | string | Yes | Description | N/A |
| `OptionalParam` | string | No | Description | `DefaultValue` |

## Usage

### Basic Usage

```powershell
.\ScriptName.ps1 -ParameterName "value"
```

### Advanced Usage

```powershell
.\ScriptName.ps1 -ParameterName "value" -OptionalParam "custom" -Verbose
```

### Automation/Pipeline Usage

```powershell
# For use in Azure DevOps or GitHub Actions
$result = .\ScriptName.ps1 -ParameterName $env:PARAMETER_VALUE
if ($result.Success) {
    Write-Host "Operation completed successfully"
}
```

## Examples

### Example 1: Basic Scenario
Description of scenario and expected output.

```powershell
.\ScriptName.ps1 -ResourceGroup "rg-prod-eastus" -Environment "production"
```

### Example 2: Advanced Scenario
Description of advanced scenario.

```powershell
.\ScriptName.ps1 -ResourceGroup "rg-prod-eastus" -Environment "production" -WhatIf
```

## Output

Description of what the script returns:
- Success/failure indicators
- Data objects returned
- Log file locations
- Generated reports

## Error Handling

Common errors and solutions:

**Error**: "Access denied to resource"
**Solution**: Ensure you have Contributor access to the target resource group

## Security Considerations

- Permissions required
- Sensitive data handling
- Audit trail considerations

## Performance

- Typical execution time
- Resource requirements
- Optimization recommendations

## Related Resources

- [Related Script](../path/to/script/)
- [Related Template](../../infrastructure/path/)
- [Blog Article](https://technicalanxiety.com/article/)

## Version History

- **1.0.0** - Initial release
- **1.1.0** - Added feature X
- **1.0.1** - Bug fix for Y

---

**Version:** 1.0.0  
**Last Updated:** YYYY-MM-DD  
**Author:** Jason Rinehart aka Technical Anxiety