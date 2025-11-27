<#
.SYNOPSIS
    Deploys Palo Alto Networks firewall VMs for East-West (internal) network security.

.DESCRIPTION
    This script deploys Palo Alto Networks VM-Series firewall appliances to provide
    internal network segmentation and security for Azure environments. The East-West
    deployment provides:
    
    - East-West traffic inspection (Azure VNet to VNet, subnet to subnet)
    - Micro-segmentation between application tiers
    - Internal threat prevention and detection
    - Application-level visibility within Azure
    - Zero-trust network architecture enforcement
    - Compliance with regulatory requirements
    
    The Palo Alto VM-Series firewall provides:
    - Next-generation firewall (NGFW) capabilities
    - Application-level visibility and control
    - Threat prevention (IPS, anti-malware, anti-spyware)
    - SSL/TLS decryption and inspection
    - User-ID integration
    - Detailed traffic logging and analytics
    
    This deployment uses managed disks for improved reliability and performance.

.PARAMETER subName
    The Azure subscription name for deployment.
    Example: 'subscription-prod-001'

.PARAMETER rgName
    The resource group name for the Palo Alto firewall.
    Example: 'rg-region1-Prod-PaloAltoEastWest'

.PARAMETER deploymentPrefix
    Prefix for the deployment name and VM naming.
    Example: 'VM-EastUS-SS-Palo03'

.PARAMETER templateFile
    Path to the ARM template file for Palo Alto East-West deployment.
    Example: '.\Templates\VM\PaloAlto-ManagedDisk\EastWest\template.PasswordAuth.json'

.PARAMETER parameterFile
    Path to the ARM template parameter file with firewall configuration.
    Example: '.\Templates\VM\PaloAlto-ManagedDisk\EastWest\template.parameter.sample.json'

.PARAMETER region
    The Azure region for deployment.
    Example: 'eastus', 'westus2'

.EXAMPLE
    .\ta-deploy-paloalto-eastwest.ps1
    
    Deploys Palo Alto East-West firewall using the configured variables.

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Palo Alto Networks VM-Series license (BYOL or PAYG)
    - Virtual network with internal subnets
    - Network security groups configured
    - User must have Contributor role on the resource group
    
    VM Configuration:
    - VM Size: Typically Standard_D3_v2 or larger
    - OS: Palo Alto Networks PAN-OS
    - Disks: Managed disks for OS and data
    - Network Interfaces: Management, Trust1, Trust2 (or more for multi-zone)
    - Public IP: Management interface only (optional)
    
    Network Architecture:
    - Management Interface: For firewall administration
    - Trust Interfaces: Multiple internal-facing interfaces for different zones
    - User-Defined Routes (UDRs) to route inter-subnet traffic through firewall
    - Hub-and-spoke or transit VNet topology
    
    Use Cases:
    - Micro-segmentation between application tiers (web, app, database)
    - Isolation of production from non-production environments
    - Compliance requirements for internal traffic inspection
    - Zero-trust network architecture implementation
    - Multi-tenant environment separation
    
    Post-Deployment:
    - Access firewall management interface
    - Complete initial configuration wizard
    - Configure security zones for each network segment
    - Create security policies for inter-zone traffic
    - Set up threat prevention profiles
    - Configure User-Defined Routes to direct traffic through firewall
    - Test traffic flow between zones
    - Configure high availability if deploying multiple firewalls
    - Set up monitoring and logging
    
    Licensing:
    - BYOL: Bring Your Own License (requires existing Palo Alto license)
    - PAYG: Pay As You Go (hourly billing through Azure Marketplace)
    
    Security Considerations:
    - Restrict management interface access to authorized IPs
    - Use strong passwords or SSH keys
    - Enable multi-factor authentication
    - Configure security policies following least-privilege principle
    - Regularly update PAN-OS to latest version
    - Implement application-based policies, not just port-based
    
    Performance Considerations:
    - Size VM appropriately for expected throughput
    - Consider multiple firewalls for load distribution
    - Monitor CPU and throughput metrics
    - Use Azure Accelerated Networking for improved performance
    
    Related Resources:
    - Palo Alto Networks VM-Series documentation
    - Azure network security best practices
    - User-Defined Route configuration
    - Hub-and-spoke network topology
    
    Impact: Provides enterprise-grade internal network segmentation and security.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and added comprehensive comments
    1.0.0 - Initial version
#>

# Configuration variables
# Update these values for your environment
$subName = "GCCS"
$rgName = "rg-region1-Prod-PaloAltoEastWest"
$deploymentPrefix = "VM-EastUS-SS-Palo03"
$templateFile = ".\Templates\VM\PaloAlto-ManagedDisk\EastWest\template.PasswordAuth.json"
$parameterFile = ".\Templates\VM\PaloAlto-ManagedDisk\EastWest\template.parameter.sample.json"
$region = "eastus"

# Generate unique deployment name with timestamp
$deploymentName = "$($deploymentPrefix)_$(Get-Date -Format yyyyMMdd_HHmm)"

Write-Output "=========================================="
Write-Output "Deploy Palo Alto East-West Firewall"
Write-Output "=========================================="
Write-Output "Subscription: $subName"
Write-Output "Resource Group: $rgName"
Write-Output "Region: $region"
Write-Output "Deployment: $deploymentName"
Write-Output ""

Try {
    # Import Azure Resource Manager module
    Write-Output "Loading AzureRM module..."
    Import-Module AzureRM -ErrorAction Stop
    
    # Authenticate to Azure
    Write-Output "Authenticating to Azure..."
    Add-AzureRMAccount
    
    # Select the target subscription
    Write-Output "Selecting subscription: $subName"
    Select-AzureRmSubscription -SubscriptionName $subName | Out-Null
    Write-Output "✓ Subscription selected"
    
    # Check if resource group exists, create if needed
    Write-Output ""
    $resourceGroup = Get-AzureRmResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if (!$resourceGroup) {
        Write-Output "Creating resource group: $rgName in $region"
        New-AzureRmResourceGroup -Name $rgName -Location $region | Out-Null
        Write-Output "✓ Resource group created"
    }
    else {
        Write-Output "✓ Using existing resource group: $rgName"
    }
    
    # Deploy Palo Alto firewall using ARM template
    Write-Output ""
    Write-Output "Deploying Palo Alto East-West firewall..."
    Write-Output "This may take 10-15 minutes..."
    New-AzureRmResourceGroupDeployment `
        -ResourceGroupName $rgName `
        -Mode Incremental `
        -Name $deploymentName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $parameterFile `
        -ErrorAction Stop
    
    Write-Output ""
    Write-Output "✓ Palo Alto East-West firewall deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Access firewall management interface"
    Write-Output "2. Complete initial configuration wizard"
    Write-Output "3. Configure security zones for each network segment"
    Write-Output "4. Create security policies for inter-zone traffic"
    Write-Output "5. Set up User-Defined Routes to direct traffic through firewall"
    Write-Output "6. Test traffic flow between zones"
}
Catch {
    Write-Error "Failed to deploy Palo Alto East-West firewall: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="