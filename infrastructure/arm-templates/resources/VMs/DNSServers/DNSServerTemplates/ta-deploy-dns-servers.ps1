<#
.SYNOPSIS
    Deploys Linux BIND DNS servers to Azure for custom DNS resolution.

.DESCRIPTION
    This script deploys Linux-based BIND DNS servers to provide custom DNS resolution
    services within Azure virtual networks. The deployment includes:
    
    - Linux VMs configured with BIND DNS server software
    - Network interfaces with static IP addresses
    - Network security groups for DNS traffic (port 53)
    - High availability configuration (multiple servers)
    - Integration with Azure virtual networks
    
    Custom DNS servers enable:
    - Internal domain name resolution
    - Conditional forwarding to on-premises DNS
    - Custom DNS zones and records
    - Split-brain DNS configurations
    - Integration with hybrid cloud architectures
    
    The script uses a custom AzureUtils module for standardized deployment
    patterns including resource group management, tagging, and deployment tracking.

.PARAMETER subName
    The Azure subscription name where DNS servers will be deployed.
    Example: 'subscription-prod-001'

.PARAMETER rgName
    The resource group name for the DNS servers.
    Example: 'rg-region1-Prod-PaaS-DNSServers'

.PARAMETER region
    The Azure region for deployment.
    Example: 'eastus', 'westus2'

.PARAMETER deploymentPrefix
    Prefix for the deployment name, used for tracking and identification.
    Example: 'US-AZR-PUDNS'

.PARAMETER templateFile
    Path to the ARM template file for Linux BIND server deployment.
    Example: '.\Templates\VM\Linux-BindServer-nCopy\template.PasswordAuth.json'

.PARAMETER parameterFile
    Path to the ARM template parameter file with deployment-specific values.
    Example: '.\Parameters\subscription-prod-001\rg-region1-Prod-PaaS-DNSServers\parameters.json'

.PARAMETER updateRGTags
    Boolean flag to update resource group tags from parameter file.
    Default: $true

.PARAMETER verboseOutput
    Boolean flag to enable verbose output during deployment.
    Default: $true

.EXAMPLE
    .\ta-deploy-dns-servers.ps1
    
    Deploys DNS servers using the configured variables in the script.

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure subscription and appropriate permissions
    - AzureUtils PowerShell module (custom module in .\Scripts\Modules\AzureUtils\)
    - ARM template files for Linux BIND server deployment
    - Parameter files with DNS server configuration
    - Virtual network and subnet must exist
    - Network security group rules for DNS traffic
    
    DNS Server Configuration:
    - OS: Linux (typically Ubuntu or CentOS)
    - Software: BIND9 DNS server
    - Ports: 53 (TCP/UDP) for DNS queries
    - Static IP addresses for consistent resolution
    - Redundant servers for high availability
    
    Post-Deployment:
    - Configure BIND zones and records
    - Set up conditional forwarders
    - Update virtual network DNS settings to point to these servers
    - Test DNS resolution from client VMs
    - Configure monitoring and alerts
    - Set up backup and disaster recovery
    
    Network Configuration:
    - Virtual networks must be configured to use these DNS servers
    - Network security groups must allow DNS traffic (port 53)
    - Consider using Azure DNS Private Zones as an alternative
    
    Related Resources:
    - BIND DNS server documentation
    - Azure custom DNS configuration
    - Virtual network DNS settings
    
    Impact: Provides custom DNS resolution services for Azure virtual networks.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and added comprehensive comments
    1.0.0 - Initial version
#>

# Configuration variables
# Update these values for your environment
$subName = "subscription-prod-001"
$rgName = "rg-region1-Prod-PaaS-DNSServers"
$region = "eastus"
$deploymentPrefix = "US-AZR-PUDNS"
$templateFile = ".\Templates\VM\Linux-BindServer-nCopy\template.PasswordAuth.json"
$parameterFile = ".\Parameters\subscription-prod-001\rg-region1-Prod-PaaS-DNSServers\parameters.json"
$updateRGTags = $true
$verboseOutput = $true

Write-Output "=========================================="
Write-Output "Deploy DNS Servers"
Write-Output "=========================================="
Write-Output "Subscription: $subName"
Write-Output "Resource Group: $rgName"
Write-Output "Region: $region"
Write-Output "Deployment Prefix: $deploymentPrefix"
Write-Output ""

Try {
    # Import custom Azure utilities module
    # This module provides standardized deployment functions
    Write-Output "Loading AzureUtils module..."
    Import-Module ".\Scripts\Modules\AzureUtils\AzureUtils.psm1" -Verbose:$verboseOutput -ErrorAction Stop
    Write-Output "✓ AzureUtils module loaded"
    
    # Set Azure subscription context
    Write-Output ""
    Write-Output "Setting Azure subscription context..."
    Set-AzureSubscriptionContext -Subscription $subName -Verbose:$verboseOutput
    Write-Output "✓ Subscription context set"
    
    # Deploy DNS servers using ARM template
    # The AzureUtils module handles resource group creation, tagging, and deployment
    Write-Output ""
    Write-Output "Deploying DNS servers..."
    New-AzureTemplateDeployment `
        -ResourceGroupName $rgName `
        -Location $region `
        -DeploymentPrefix $deploymentPrefix `
        -TemplateFilePath $templateFile `
        -ParameterFilePath $parameterFile `
        -IncludeParameterTags:$updateRGTags `
        -Verbose:$verboseOutput
    
    Write-Output ""
    Write-Output "✓ DNS servers deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Configure BIND zones and DNS records"
    Write-Output "2. Set up conditional forwarders for hybrid scenarios"
    Write-Output "3. Update virtual network DNS settings to use these servers"
    Write-Output "4. Test DNS resolution from client VMs"
    Write-Output "5. Configure monitoring and alerts"
}
Catch {
    Write-Error "Failed to deploy DNS servers: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="