# MCP Server Setup Guide

## Overview

This guide helps you set up Model Context Protocol (MCP) servers to extend Kiro's capabilities for your Technical Anxiety repository. The recommended configuration provides enhanced Azure integration, advanced documentation tools, and comprehensive file operations.

## Prerequisites

### Install UV Package Manager

MCP servers use `uvx` (part of the `uv` Python package manager) to run. Install it first:

**Windows (PowerShell):**
```powershell
# Using pip
pip install uv

# Using Chocolatey
choco install uv

# Using Scoop
scoop install uv
```

**Verify Installation:**
```bash
uv --version
uvx --version
```

## MCP Configuration

### Step 1: Copy Configuration Template

Copy the MCP configuration from the template:

```bash
# Copy template to settings directory
cp .kiro/templates/mcp-configuration.json .kiro/settings/mcp.json
```

### Step 2: Configure MCP Servers

The configuration includes these servers optimized for your workflow:

#### 1. Filesystem Server
**Purpose:** Advanced file operations and search
**Auto-approved tools:**
- `read_file` - Enhanced file reading
- `list_directory` - Advanced directory listing
- `search_files` - Repository-wide file search

#### 2. Fetch Server  
**Purpose:** Web content retrieval and link validation
**Auto-approved tools:**
- `fetch` - Retrieve web content for blog article validation

#### 3. Azure CLI Server
**Purpose:** Direct Azure resource management
**Auto-approved tools:**
- `az_account_show` - Check Azure authentication
- `az_resource_list` - List Azure resources
- `az_deployment_validate` - Validate Bicep templates

#### 4. Git Server
**Purpose:** Enhanced version control operations
**Auto-approved tools:**
- `git_status` - Repository status
- `git_log` - Commit history
- `git_diff` - Change analysis

#### 5. Markdown Server
**Purpose:** Advanced markdown processing
**Auto-approved tools:**
- `validate_markdown` - Markdown syntax validation
- `extract_links` - Link extraction and validation
- `format_table` - Table formatting

#### 6. Code Analysis Server
**Purpose:** Static code analysis and linting
**Auto-approved tools:**
- `lint_powershell` - PowerShell script analysis
- `validate_json` - JSON syntax validation
- `check_syntax` - General syntax checking

## Usage Examples

### Azure Resource Management

```bash
# List all storage accounts in subscription
az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}"

# Validate Bicep template
az deployment group validate --resource-group myRG --template-file main.bicep
```

### Documentation Enhancement

```bash
# Validate all markdown files
find . -name "*.md" -exec markdown-validate {} \;

# Extract and validate all links
markdown-extract-links README.md | xargs -I {} curl -I {}
```

### Repository Analysis

```bash
# Search for all Bicep templates
search-files --pattern "*.bicep" --include-content

# Analyze PowerShell scripts
lint-powershell scripts/**/*.ps1
```

## Integration with Automation

### Agent Hook Integration

The MCP servers integrate with your agent hooks to provide:

1. **Automatic Template Validation:** When Bicep files are saved, Azure CLI validates them
2. **Link Validation:** When README files are updated, fetch server validates blog links
3. **Code Quality:** PowerShell scripts are automatically linted on save
4. **Repository Health:** Git server provides enhanced change tracking

### Manual Operations Enhancement

Your manual maintenance operations are enhanced with:

- **Bulk Template Validation:** Azure CLI validates all templates simultaneously
- **Comprehensive Link Checking:** Fetch server validates all blog article links
- **Advanced File Operations:** Filesystem server provides powerful search and analysis
- **Code Quality Reports:** Analysis server provides detailed code quality metrics

## Troubleshooting

### Common Issues

**Issue:** `uvx: command not found`
**Solution:** Install UV package manager: `pip install uv`

**Issue:** MCP server connection failed
**Solution:** Check server logs and ensure UV is properly installed

**Issue:** Azure CLI commands fail
**Solution:** Ensure you're logged into Azure: `az login`

### Server Status

Check MCP server status in Kiro:
1. Open Kiro feature panel
2. Navigate to MCP Server view
3. Verify all servers show "Connected" status
4. Restart servers if needed

### Log Analysis

MCP servers log to `FASTMCP_LOG_LEVEL=ERROR` by default. For debugging:

1. Change log level to `DEBUG` in configuration
2. Restart Kiro
3. Check server logs for detailed information

## Security Considerations

### Auto-Approved Tools

The configuration auto-approves safe, read-only operations:
- File reading and directory listing
- Git status and log viewing
- Azure resource listing (read-only)
- Markdown validation

### Manual Approval Required

These operations require manual approval:
- File writing and modification
- Azure resource creation/modification
- Git commits and pushes
- Destructive operations

### Best Practices

1. **Regular Updates:** Keep MCP servers updated via `uvx`
2. **Permission Review:** Regularly review auto-approved tools
3. **Audit Logs:** Monitor MCP server usage in logs
4. **Secure Credentials:** Ensure Azure CLI uses secure authentication

## Advanced Configuration

### Custom Server Addition

To add additional MCP servers:

1. Add server configuration to `mcp.json`
2. Restart Kiro to load new server
3. Configure auto-approval for trusted tools
4. Test server functionality

### Performance Optimization

- **Concurrent Operations:** MCP servers support parallel execution
- **Caching:** Some servers cache results for better performance
- **Resource Limits:** Configure appropriate timeouts and limits

## Support Resources

- **MCP Documentation:** [Model Context Protocol Docs](https://modelcontextprotocol.io/)
- **UV Package Manager:** [UV Documentation](https://docs.astral.sh/uv/)
- **Azure CLI:** [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- **Kiro MCP Guide:** Use command palette → "MCP" for Kiro-specific help

---

**Configuration Template:** `.kiro/templates/mcp-configuration.json`  
**Target Location:** `.kiro/settings/mcp.json`  
**Last Updated:** 2025-01-01