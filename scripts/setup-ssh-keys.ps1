#Requires -Version 5.1
<#
.SYNOPSIS
    Generate and configure SSH keys for Git repository access

.DESCRIPTION
    This script generates SSH keys for the specified user and configures Git to use SSH authentication.
    It creates both RSA and Ed25519 keys for maximum compatibility.

.PARAMETER Username
    The username for which to generate SSH keys (required)

.PARAMETER KeyPath
    Path where SSH keys should be stored (default: ~/.ssh)

.PARAMETER Force
    Overwrite existing keys if they exist

.EXAMPLE
    .\setup-ssh-keys.ps1 -Username "myuser"

.EXAMPLE
    .\setup-ssh-keys.ps1 -Username "myuser" -Force

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
    
    [Parameter(Mandatory=$false)]
    [string]$KeyPath = "$env:USERPROFILE\.ssh",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Ensure SSH directory exists
if (-not (Test-Path $KeyPath)) {
    Write-Output "Creating SSH directory: $KeyPath"
    New-Item -ItemType Directory -Path $KeyPath -Force | Out-Null
}

# Set proper permissions on SSH directory (Windows)
if ($PSCmdlet.ShouldProcess($KeyPath, "Set SSH directory permissions")) {
    try {
        $acl = Get-Acl $KeyPath
        $acl.SetAccessRuleProtection($true, $false)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $KeyPath -AclObject $acl
        Write-Output "✓ SSH directory permissions configured"
    }
    catch {
        Write-Warning "Could not set SSH directory permissions: $($_.Exception.Message)"
    }
}

# Generate Ed25519 key (recommended)
$ed25519KeyPath = Join-Path $KeyPath "id_ed25519_$Username"
if (-not (Test-Path $ed25519KeyPath) -or $Force) {
    Write-Output "Generating Ed25519 SSH key for $Username..."
    if ($PSCmdlet.ShouldProcess($ed25519KeyPath, "Generate Ed25519 SSH key")) {
        $sshKeygenArgs = @(
            "-t", "ed25519"
            "-C", "$Username@$(hostname)"
            "-f", $ed25519KeyPath
            "-N", ""
        )
        
        & ssh-keygen @sshKeygenArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "✓ Ed25519 key generated: $ed25519KeyPath"
        } else {
            Write-Error "Failed to generate Ed25519 key"
            return
        }
    }
} else {
    Write-Output "Ed25519 key already exists: $ed25519KeyPath"
}

# Generate RSA key (for compatibility)
$rsaKeyPath = Join-Path $KeyPath "id_rsa_$Username"
if (-not (Test-Path $rsaKeyPath) -or $Force) {
    Write-Output "Generating RSA SSH key for $Username..."
    if ($PSCmdlet.ShouldProcess($rsaKeyPath, "Generate RSA SSH key")) {
        $sshKeygenArgs = @(
            "-t", "rsa"
            "-b", "4096"
            "-C", "$Username@$(hostname)"
            "-f", $rsaKeyPath
            "-N", ""
        )
        
        & ssh-keygen @sshKeygenArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "✓ RSA key generated: $rsaKeyPath"
        } else {
            Write-Error "Failed to generate RSA key"
            return
        }
    }
} else {
    Write-Output "RSA key already exists: $rsaKeyPath"
}

# Create SSH config file
$sshConfigPath = Join-Path $KeyPath "config"
$configContent = @"
# SSH Configuration for $Username
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile $ed25519KeyPath
    IdentitiesOnly yes
    AddKeysToAgent yes

# Azure DevOps configuration
Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    User git
    IdentityFile $ed25519KeyPath
    IdentitiesOnly yes
    AddKeysToAgent yes

# GitLab configuration
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile $ed25519KeyPath
    IdentitiesOnly yes
    AddKeysToAgent yes

# Bitbucket configuration
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile $ed25519KeyPath
    IdentitiesOnly yes
    AddKeysToAgent yes
"@

if ($PSCmdlet.ShouldProcess($sshConfigPath, "Create SSH config file")) {
    $configContent | Out-File -FilePath $sshConfigPath -Encoding UTF8 -Force
    Write-Output "✓ SSH config created: $sshConfigPath"
}

# Display public keys
Write-Output "`n" + "="*60
Write-Output "SSH KEYS GENERATED FOR: $Username"
Write-Output "="*60

if (Test-Path "$ed25519KeyPath.pub") {
    Write-Output "`nEd25519 Public Key (RECOMMENDED):"
    Write-Output "-" * 40
    Get-Content "$ed25519KeyPath.pub"
}

if (Test-Path "$rsaKeyPath.pub") {
    Write-Output "`nRSA Public Key (COMPATIBILITY):"
    Write-Output "-" * 40
    Get-Content "$rsaKeyPath.pub"
}

Write-Output "`n" + "="*60
Write-Output "NEXT STEPS:"
Write-Output "="*60
Write-Output "1. Copy the Ed25519 public key above"
Write-Output "2. Add it to your Git provider:"
Write-Output "   - GitHub: Settings > SSH and GPG keys > New SSH key"
Write-Output "   - Azure DevOps: User Settings > SSH public keys > Add"
Write-Output "   - GitLab: User Settings > SSH Keys > Add key"
Write-Output "3. Test the connection:"
Write-Output "   ssh -T git@github.com"
Write-Output "4. Configure Git to use SSH URLs:"
Write-Output "   git remote set-url origin git@github.com:username/repo.git"
Write-Output "`nKeys stored in: $KeyPath"
Write-Output "Config file: $sshConfigPath"