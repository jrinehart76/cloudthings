# [Template Name]

## Overview

Brief description of what this Bicep template deploys and its primary use case.

**Blog Article:** [Article Title](https://technicalanxiety.com/article-slug/)

## Architecture

Describe the resources deployed and their relationships:

- **Resource 1**: Purpose and configuration
- **Resource 2**: Purpose and configuration
- **Dependencies**: How resources interact

## Parameters

| Parameter | Type | Description | Default | Required |
|-----------|------|-------------|---------|----------|
| `parameterName` | string | Description of parameter | `defaultValue` | Yes/No |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `outputName` | string | Description of what's returned |

## Deployment

### Prerequisites

- Azure CLI or PowerShell Az module
- Contributor access to target subscription
- [Any specific requirements]

### Quick Deploy

```bash
# Azure CLI
az deployment group create \
  --resource-group <RESOURCE_GROUP_NAME> \
  --template-file main.bicep \
  --parameters @main.parameters.json

# PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<RESOURCE_GROUP_NAME>" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "main.parameters.json"
```

### Validation

```bash
# Validate template before deployment
az deployment group validate \
  --resource-group <RESOURCE_GROUP_NAME> \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

## Examples

### Basic Deployment
Description and parameter file for basic scenario.

### Advanced Configuration
Description and parameter file for advanced scenario.

## Security Considerations

- List security features implemented
- Recommended additional security measures
- Compliance considerations

## Cost Considerations

- Estimated monthly costs for typical deployment
- Cost optimization recommendations
- Scaling cost implications

## Troubleshooting

### Common Issues

**Issue**: Description of common problem
**Solution**: How to resolve it

## Related Resources

- [Related Template 1](../path/to/template/)
- [Related Script](../../scripts/path/)
- [Blog Article Series](https://technicalanxiety.com/series/)

## Version History

- **1.0.0** - Initial release
- **1.1.0** - Added feature X
- **1.0.1** - Bug fix for Y

---

**Version:** 1.0.0  
**Last Updated:** YYYY-MM-DD  
**Author:** Jason Rinehart aka Technical Anxiety