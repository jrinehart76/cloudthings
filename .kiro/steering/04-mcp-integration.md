---
inclusion: manual
---

# MCP Integration & Enhanced Capabilities Reference

## Configured MCP Servers
1. **Filesystem Server** - Advanced file operations and repository-wide search
2. **Fetch Server** - Web content retrieval and blog article link validation  
3. **Azure CLI Server** - Direct Azure resource management and template validation
4. **Git Server** - Enhanced version control operations and change analysis
5. **Markdown Server** - Advanced markdown processing and link validation
6. **Code Analysis Server** - Static analysis and linting for PowerShell and other code

## Auto-Approved Operations
Safe, read-only operations are auto-approved for seamless workflow:
- File reading, directory listing, and repository search
- Git status, log viewing, and diff analysis
- Azure resource listing and template validation
- Markdown syntax validation and link extraction
- Code syntax checking and basic linting

## Enhanced Capabilities

### Template Enhancement
- **Template Validation**: Azure CLI server validates templates on save
- **Parameter Extraction**: Advanced file operations extract parameter information
- **Documentation Generation**: Markdown server formats parameter tables
- **Link Validation**: Fetch server validates blog article references

### Script Enhancement  
- **Syntax Analysis**: Code analysis server provides comprehensive linting
- **Help Validation**: Advanced parsing validates comment-based help
- **Security Scanning**: Automated detection of hardcoded secrets
- **Cross-Reference**: File system server finds related implementations

### Documentation Enhancement
- **Link Validation**: Fetch server validates all blog article links
- **Markdown Processing**: Advanced formatting and table generation
- **Cross-Reference Generation**: Automatic discovery of related content
- **Image Optimization**: Processing and optimization of documentation assets

## Usage Patterns
- **Development Workflow**: MCP servers provide real-time validation and enhancement
- **Quality Assurance**: Continuous validation and comprehensive analysis
- **Blog Integration**: Seamless connection between implementations and articles
- **Community Contribution**: Enhanced review and quality standards