---
inclusion: fileMatch
fileMatchPattern: "**/*.{bicep,ps1,py,js,ts,json}"
---

# Code and Infrastructure Standards

## Bicep/ARM Templates
- Use latest API versions (2023+ preferred)
- Include comprehensive parameter descriptions and metadata
- Implement proper resource naming conventions (environment-workload-resource-instance)
- Add resource tags for governance (Environment, Owner, CostCenter, Project)
- Include outputs for key resource properties
- Use modules for reusable components

## PowerShell Scripts
- Follow approved verb-noun naming (Get-AzResource, Set-AzPolicy, etc.)
- Include comprehensive comment-based help with examples
- Implement proper error handling with try/catch blocks
- Use parameter validation and mandatory parameters where appropriate
- Include progress indicators for long-running operations
- Output structured objects for pipeline compatibility

## Python Scripts
- Follow PEP 8 style guidelines
- Include type hints for function parameters and returns
- Use virtual environments and requirements.txt
- Implement proper logging with appropriate levels
- Include docstrings with examples
- Handle exceptions gracefully with specific error messages

## JavaScript/Node.js
- Use modern ES6+ syntax and features
- Implement proper async/await patterns
- Include comprehensive JSDoc comments
- Use environment variables for configuration
- Implement proper error handling and logging
- Follow security best practices (input validation, sanitization)

## Security Standards
- Implement Zero Trust principles
- Use managed identities over service principals when possible
- Enable encryption at rest and in transit by default
- Implement least privilege access patterns
- Use Azure Key Vault for secrets management
- Enable audit logging and monitoring