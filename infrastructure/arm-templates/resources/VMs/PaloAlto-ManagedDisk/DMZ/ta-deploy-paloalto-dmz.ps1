<#
.SYNOPSIS
    Deploys Palo Alto Networks firewall VMs for DMZ (perimeter) network security.

.DESCRIPTION
    This script deploys Palo Alto Networks VM-Series firewall appliances to provide
    perimeter security for Azure environments. The DMZ deployment provides:
    
    - North-South traffic inspection (Internet to Azure)
    - Inbound application protection
    - Outbound internet access control
    - Advanced threat prevention
    - URL filtering and content inspection
    - VPN gateway capabilities
    - High availability configurations
    
    The Palo Alto VM-Series firewall provides:
    - Next-generation firewall (NGFW) capabilities
    - Application-level visibility and control
    - Threat prevention (IPS, anti-malware, anti-spyware)
    - SSL/TLS decryption and inspection
    - User-ID integration
    - GlobalProtect VPN
    
    This deployment uses managed disks for improved reliability and performance.

.PARAMETER subName
    The Azure subscription name for deployment.
    Example: 'subscription-prod-001'

.PARAMETER rgName
    The resource group name for the Palo Alto firewall.
    Example: 'rg-region1-Prod-PaloAlto'

.PARAMETER deploymentPrefix
    Prefix for the deployment name and VM naming.
    Example: 'VM-EastUS-SS-Palo01'

.PARAMETER templateFile
    Path to the ARM template file for Palo Alto DMZ deployment.
    Example: '.\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.PasswordAuth.json'

.PARAMETER parameterFile
    Path to the ARM template parameter file with firewall configuration.
    Example: '.\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.parameter.sample.json'

.PARAMETER region
    The Azure region for deployment.
    Example: 'eastus', 'westus2'

.EXAMPLE
    .\ta-deploy-paloalto-dmz.ps1
    
    Deploys Palo Alto DMZ firewall using the configured variables.

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure subscription with appropriate permissions
    - Palo Alto Networks VM-Series license (BYOL or PAYG)
    - Virtual network with DMZ subnet
    - Network security groups configured
    - Public IP addresses for management and data interfaces
    - User must have Contributor role on the resource group
    
    VM Configuration:
    - VM Size: Typically Standard_D3_v2 or larger
    - OS: Palo Alto Networks PAN-OS
    - Disks: Managed disks for OS and data
    - Network Interfaces: Management, Untrust (external), Trust (internal)
    - Public IPs: Management and Untrust interfaces
    
    Network Architecture:
    - Management Interface: For firewall administration
    - Untrust Interface: External/Internet-facing
    - Trust Interface: Internal/Azure-facing
    - User-Defined Routes (UDRs) to route traffic through firewall
    
    Post-Deployment:
    - Access firewall management interface via public IP
    - Complete initial configuration wizard
    - Configure security policies and NAT rules
    - Set up threat prevention profiles
    - Configure User-Defined Routes to direct traffic through firewall
    - Test traffic flow and policy enforcement
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
    
    Related Resources:
    - Palo Alto Networks VM-Series documentation
    - Azure network security best practices
    - User-Defined Route configuration
    
    Impact: Provides enterprise-grade perimeter security for Azure environments.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and added comprehensive comments
    1.0.0 - Initial version
#>

# Configuration variables
# Update these values for your environment
$subName = "GCCS"
$rgName = "rg-region1-Prod-PaloAlto"
$deploymentPrefix = "VM-EastUS-SS-Palo01"
$templateFile = ".\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.PasswordAuth.json"
$parameterFile = ".\Templates\VM\PaloAlto-ManagedDisk\DMZ\template.parameter.sample.json"
$region = "eastus"

# Generate unique deployment name with timestamp
$deploymentName = "$($deploymentPrefix)_$(Get-Date -Format yyyyMMdd_HHmm)"

Write-Output "=========================================="
Write-Output "Deploy Palo Alto DMZ Firewall"
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
    Write-Output "Deploying Palo Alto DMZ firewall..."
    Write-Output "This may take 10-15 minutes..."
    New-AzureRmResourceGroupDeployment `
        -ResourceGroupName $rgName `
        -Mode Incremental `
        -Name $deploymentName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $parameterFile `
        -ErrorAction Stop
    
    Write-Output ""
    Write-Output "✓ Palo Alto DMZ firewall deployed successfully"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Access firewall management interface via public IP"
    Write-Output "2. Complete initial configuration wizard"
    Write-Output "3. Configure security policies and NAT rules"
    Write-Output "4. Set up User-Defined Routes to direct traffic through firewall"
    Write-Output "5. Test traffic flow and policy enforcement"
}
Catch {
    Write-Error "Failed to deploy Palo Alto DMZ firewall: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="