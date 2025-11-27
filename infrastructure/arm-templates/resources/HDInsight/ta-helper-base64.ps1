<#
.SYNOPSIS
    Helper utility to extract certificates from Azure Key Vault and convert to Base64 for ARM templates.

.DESCRIPTION
    This utility script retrieves PFX certificates from Azure Key Vault and converts them
    to Base64-encoded format for use in ARM template deployments. The script:
    
    1. Authenticates to Azure and connects to the specified Key Vault
    2. Retrieves the certificate from Key Vault as a secret
    3. Converts the certificate bytes to a PFX file
    4. Applies a password to the PFX certificate
    5. Exports the PFX file to disk
    6. Converts the PFX to Base64 encoding
    7. Saves the Base64 string to a text file
    
    This is particularly useful for HDInsight deployments that require certificates
    to be passed as Base64-encoded strings in ARM template parameters.
    
    The Base64-encoded certificate can then be used in ARM templates for:
    - HDInsight cluster SSL/TLS configuration
    - Application gateway certificates
    - Service Fabric cluster security
    - Any ARM template requiring certificate parameters

.PARAMETER vaultName
    The name of the Azure Key Vault containing the certificate.
    Example: 'kv-platform-prod'

.PARAMETER certificateName
    The name of the certificate in Key Vault.
    Example: 'hdi-cluster-cert'

.PARAMETER password
    The password to apply to the exported PFX file.
    This password will be required when using the certificate.
    Can also be retrieved from Key Vault if stored as a secret.

.PARAMETER pfxPath
    The local file path where the PFX certificate will be saved.
    Example: 'C:\Temp\certificate.pfx'

.PARAMETER pfxBaseSixtyFour
    The local file path where the Base64-encoded certificate will be saved.
    This file contains the string to use in ARM template parameters.
    Example: 'C:\Temp\certificate-base64.txt'

.PARAMETER subscriptionId
    The Azure subscription ID containing the Key Vault.
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.EXAMPLE
    # Update the variables in the script and run
    .\ta-helper-base64.ps1
    
    # The script will:
    # 1. Prompt for Azure authentication
    # 2. Export the certificate to the specified PFX path
    # 3. Create a Base64 text file for ARM template use

.NOTES
    Author: David Nite
    Contributors: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure PowerShell module (AzureRM or Az)
    - Access to Azure Key Vault with Get permissions on certificates and secrets
    - Certificate must exist in Key Vault
    - Local file system write permissions
    
    Usage Pattern:
    1. Update the variables at the top of the script
    2. Run the script to authenticate and export
    3. Copy the Base64 string from the output file
    4. Paste into ARM template parameter file
    
    Security Considerations:
    - The exported PFX file contains the private key
    - Store PFX files securely and delete after use
    - Use strong passwords for PFX protection
    - Consider using Key Vault references in ARM templates instead of Base64 when possible
    - Never commit PFX files or Base64 certificates to source control
    
    Certificate Validation:
    - The script tests the PFX with Get-PfxCertificate
    - Verify the thumbprint matches the Key Vault certificate
    - Test the certificate before using in production deployments
    
    Related Resources:
    - HDInsight ARM templates requiring certificate parameters
    - Key Vault certificate management documentation
    - ARM template secure parameter handling
    
    Impact: Enables secure certificate extraction and formatting for ARM template deployments.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and added parameter descriptions
    1.0.0 - Initial version (dnite)
#>

# Configuration variables
# Update these values for your environment
$vaultName = "AKV-AM-EastUS-DevOps-POC"
$certificateName = 'custa-msp-HdiTemplate'
$secretName = "custa-msp-HdiTemplate-pfx"
$password = '7F1R&vYLIegy71*t'  # Certificate password - can also be retrieved from Key Vault
$pfxPath = "C:\Users\dave\Downloads\akv-am-eastus-devops-poc-custa-msp-HdiTemplate-withpassword.pfx"
$pfxBaseSixtyFour = "C:\Users\dave\Downloads\pfx_with_password.txt"
$subscriptionId = ""  # Add your subscription ID

Write-Output "=========================================="
Write-Output "Certificate Base64 Conversion Utility"
Write-Output "=========================================="
Write-Output "Key Vault: $vaultName"
Write-Output "Certificate: $certificateName"
Write-Output ""

Try {
    # Authenticate to Azure
    Write-Output "Authenticating to Azure..."
    Login-AzureRmAccount
    Get-AzureRmSubscription
    
    if ($subscriptionId) {
        Set-AzureRmContext -SubscriptionId $subscriptionId
        Write-Output "✓ Connected to subscription: $subscriptionId"
    }
    
    # Retrieve certificate from Key Vault
    Write-Output ""
    Write-Output "Retrieving certificate from Key Vault..."
    $kvSecret = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $certificateName -ErrorAction Stop
    Write-Output "✓ Certificate retrieved from Key Vault"
    
    # Convert Base64 secret to certificate bytes
    $kvSecretBytes = [System.Convert]::FromBase64String($kvSecret.SecretValueText)
    $certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $certCollection.Import($kvSecretBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    
    # Export certificate with password protection
    Write-Output "Exporting certificate with password protection..."
    $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
    [System.IO.File]::WriteAllBytes($pfxPath, $protectedCertificateBytes)
    Write-Output "✓ PFX file saved to: $pfxPath"
    
    # Validate the exported certificate
    Write-Output ""
    Write-Output "Validating exported certificate..."
    $pfxCert = Get-PfxCertificate -FilePath $pfxPath
    Write-Output "✓ Certificate validated"
    Write-Output "  Thumbprint: $($pfxCert.Thumbprint)"
    Write-Output "  Subject: $($pfxCert.Subject)"
    Write-Output "  Expiration: $($pfxCert.NotAfter)"
    
    # Convert PFX to Base64 for ARM template use
    Write-Output ""
    Write-Output "Converting certificate to Base64..."
    $fc_bytes = Get-Content $pfxPath -Encoding Byte
    [System.Convert]::ToBase64String($fc_bytes) | Out-File $pfxBaseSixtyFour
    Write-Output "✓ Base64 file saved to: $pfxBaseSixtyFour"
    
    Write-Output ""
    Write-Output "✓ Certificate conversion complete"
    Write-Output ""
    Write-Output "NEXT STEPS:"
    Write-Output "1. Copy the Base64 string from: $pfxBaseSixtyFour"
    Write-Output "2. Paste into your ARM template parameter file"
    Write-Output "3. Securely delete the PFX file after use"
    Write-Output "4. Never commit certificates to source control"
}
Catch {
    Write-Error "Failed to process certificate: $_"
    throw
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Conversion Complete"
Write-Output "=========================================="
