#Requires -Version 5.1
<#
.SYNOPSIS
    Configure Git repository to use SSH authentication

.DESCRIPTION
    This script configures the current Git repository to use SSH instead of HTTPS
    and sets up Git user configuration

.PARAMETER Username
    GitHub username (required)

.PARAMETER Email
    Email address for Git configuration (required)

.PARAMETER RepoName
    Repository name (optional, will try to detect from current remote)

.EXAMPLE
    .\configure-git-ssh-generic.ps1 -Username "myuser" -Email "user@example.com"

.EXAMPLE
    .\configure-git-ssh-generic.ps1 -Username "myuser" -Email "user@example.com" -RepoName "my-repo"

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Version: 1.0.0
    Created: 2025-01-01
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="GitHub username")]
    [string]$Username,
    
    [Parameter(Mandatory=$true, HelpMessage="Email address for Git configuration")]
    [string]$Email,
    
    [Parameter(Mandatory=$false, HelpMessage="Repository name (optional)")]
    [string]$RepoName
)

Write-Output "Configuring Git for SSH authentication..."
Write-Output "User: $Username"
Write-Output "Email: $Email"
Write-Output ""

# Check if we're in a Git repository
if (-not (Test-Path ".git")) {
    Write-Error "This directory is not a Git repository. Please run this script from the repository root."
    exit 1
}

# Configure Git user settings
Write-Output "Setting Git user configuration..."
git config user.name $Username
git config user.email $Email

# Get current remote URL
$currentRemote = git remote get-url origin 2>$null
if ($currentRemote) {
    Write-Output "Current remote URL: $currentRemote"
    
    # Convert HTTPS to SSH if needed
    if ($currentRemote -like "https://github.com/*") {
        $sshUrl = $currentRemote -replace "https://github.com/", "git@github.com:"
        Write-Output "Converting to SSH URL: $sshUrl"
        git remote set-url origin $sshUrl
        Write-Output "✓ Remote URL updated to use SSH"
    } elseif ($currentRemote -like "git@github.com:*") {
        Write-Output "✓ Repository already configured for SSH"
    } else {
        Write-Output "Unknown remote URL format. Please configure manually."
    }
} else {
    # Set up new remote if RepoName provided
    if ($RepoName) {
        $sshUrl = "git@github.com:$Username/$RepoName.git"
        Write-Output "Setting up SSH remote: $sshUrl"
        git remote add origin $sshUrl
        Write-Output "✓ SSH remote added"
    } else {
        Write-Warning "No remote found and no repository name provided. Please add remote manually:"
        Write-Output "git remote add origin git@github.com:$Username/REPO-NAME.git"
    }
}

# Test SSH connection
Write-Output ""
Write-Output "Testing SSH connection to GitHub..."
$testResult = ssh -T git@github.com 2>&1
if ($LASTEXITCODE -eq 1) {
    Write-Output "✓ SSH connection successful!"
    Write-Output "Response: $testResult"
} else {
    Write-Warning "SSH connection test failed. Please ensure:"
    Write-Output "1. Your SSH key is added to GitHub"
    Write-Output "2. SSH agent is running"
    Write-Output "3. Your SSH key is loaded: ssh-add ~/.ssh/id_ed25519_$Username"
}

# Display final configuration
Write-Output ""
Write-Output "============================================================"
Write-Output "GIT CONFIGURATION SUMMARY"
Write-Output "============================================================"
Write-Output "User Name: $(git config user.name)"
Write-Output "User Email: $(git config user.email)"
$finalRemote = git remote get-url origin 2>$null
if ($finalRemote) {
    Write-Output "Remote URL: $finalRemote"
}
Write-Output ""
Write-Output "To test your setup:"
Write-Output "1. Make a small change to a file"
Write-Output "2. git add ."
Write-Output "3. git commit -m 'Test SSH setup'"
Write-Output "4. git push"