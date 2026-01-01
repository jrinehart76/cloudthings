#Requires -Version 5.1
<#
.SYNOPSIS
    Generate and configure SSH keys for Git repository access

.DESCRIPTION
    This script generates SSH keys for the specified user and configures Git to use SSH authentication.
    It creates both RSA and Ed25519 keys for maximum compatibility.

.PARAMETER Username
    The username for which to generate SSH keys (required)

.PARAMETER Email
    Email address for Git configuration (required)

.PARAMETER KeyPath
    Path where SSH keys should be stored (default: ~/.ssh)

.PARAMETER Force
    Overwrite existing keys if they exist

.EXAMPLE
    .\setup-ssh-keys-generic.ps1 -Username "myuser" -Email "user@example.com"

.EXAMPLE
    .\setup-ssh-keys-generic.ps1 -Username "myuser" -Email "user@example.com" -Force

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Version: 1.0.0
    Created: 2025-01-01
    
    Prerequisites:
    - Git for Windows (includes ssh-keygen)
    - PowerShell 5.1 or later
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true, HelpMessage="Username for SSH key generation")]
    [string]$Username,
    
    [Parameter(Mandatory=$true, HelpMessage="Email address for Git configuration")]
    [string]$Email,
    
    [Parameter(Mandatory=$false)]
    [string]$KeyPath = "$env:USERPROFILE\.ssh",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

Write-Output "Setting up SSH keys for: $Username"
Write-Output "Email: $Email"
Write-Output "SSH directory: $KeyPath"

# Create SSH directory if it doesn't exist
if (-not (Test-Path $KeyPath)) {
    Write-Output "Creating SSH directory..."
    New-Item -ItemType Directory -Path $KeyPath -Force | Out-Null
}

# Generate Ed25519 key
$ed25519Key = Join-Path $KeyPath "id_ed25519_$Username"
if (-not (Test-Path $ed25519Key) -or $Force) {
    Write-Output "Generating Ed25519 SSH key..."
    & ssh-keygen -t ed25519 -C "$Email" -f "$ed25519Key" -q -N '""'
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✓ Ed25519 key generated successfully"
    } else {
        Write-Error "Failed to generate Ed25519 key"
        exit 1
    }
} else {
    Write-Output "Ed25519 key already exists"
}

# Generate RSA key for compatibility
$rsaKey = Join-Path $KeyPath "id_rsa_$Username"
if (-not (Test-Path $rsaKey) -or $Force) {
    Write-Output "Generating RSA SSH key..."
    & ssh-keygen -t rsa -b 4096 -C "$Email" -f "$rsaKey" -q -N '""'
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✓ RSA key generated successfully"
    } else {
        Write-Error "Failed to generate RSA key"
        exit 1
    }
} else {
    Write-Output "RSA key already exists"
}

# Configure Git user settings
Write-Output "Configuring Git user settings..."
git config user.name $Username
git config user.email $Email

# Display the public keys
Write-Output ""
Write-Output "============================================================"
Write-Output "SSH KEYS GENERATED FOR: $Username"
Write-Output "============================================================"

if (Test-Path "$ed25519Key.pub") {
    Write-Output ""
    Write-Output "Ed25519 Public Key (RECOMMENDED):"
    Write-Output "----------------------------------------"
    Get-Content "$ed25519Key.pub"
}

if (Test-Path "$rsaKey.pub") {
    Write-Output ""
    Write-Output "RSA Public Key (COMPATIBILITY):"
    Write-Output "----------------------------------------"
    Get-Content "$rsaKey.pub"
}

Write-Output ""
Write-Output "============================================================"
Write-Output "NEXT STEPS:"
Write-Output "============================================================"
Write-Output "1. Copy the Ed25519 public key above"
Write-Output "2. Add it to your Git provider:"
Write-Output "   - GitHub: Settings > SSH and GPG keys > New SSH key"
Write-Output "   - Azure DevOps: User Settings > SSH public keys > Add"
Write-Output "   - GitLab: User Settings > SSH Keys > Add key"
Write-Output "3. Test the connection:"
Write-Output "   ssh -T git@github.com"
Write-Output "4. Configure this repository to use SSH:"
Write-Output "   git remote set-url origin git@github.com:USERNAME/REPOSITORY.git"
Write-Output ""
Write-Output "Keys stored in: $KeyPath"