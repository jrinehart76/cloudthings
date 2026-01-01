# SSH Key Setup Scripts

This directory contains scripts to generate and configure SSH keys for Git repository access.

## Quick Start

### Option 1: PowerShell Script (Recommended)

```powershell
# Run from repository root
.\scripts\setup-ssh-keys-generic.ps1 -Username "yourusername" -Email "your.email@example.com"
```

### Option 2: Advanced Configuration

```powershell
# Generate keys and configure Git separately
.\scripts\setup-ssh-keys.ps1 -Username "yourusername"
.\scripts\configure-git-ssh-generic.ps1 -Username "yourusername" -Email "your.email@example.com"
```

### Option 3: Command Prompt

```cmd
# Run from repository root
.\scripts\setup-ssh-keys.cmd
```

### Option 4: Manual Setup

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/id_ed25519_yourusername

# Generate RSA key (compatibility)
ssh-keygen -t rsa -b 4096 -C "your.email@example.com" -f ~/.ssh/id_rsa_yourusername
```

## What the Scripts Do

1. **Create SSH directory** (`~/.ssh`) with proper permissions
2. **Generate Ed25519 key** (modern, secure, recommended)
3. **Generate RSA key** (compatibility with older systems)
4. **Create SSH config** for common Git providers
5. **Display public keys** for copying to Git providers

## Generated Files

```text
~/.ssh/
├── id_ed25519_yourusername      # Ed25519 private key
├── id_ed25519_yourusername.pub  # Ed25519 public key (copy this)
├── id_rsa_yourusername          # RSA private key
├── id_rsa_yourusername.pub      # RSA public key
└── config                       # SSH configuration
```

## Adding Keys to Git Providers

### GitHub

1. Go to [GitHub SSH Settings](https://github.com/settings/keys)
2. Click "New SSH key"
3. Paste the **Ed25519 public key** content
4. Give it a descriptive title (e.g., "yourusername-workstation")
5. Click "Add SSH key"

### Azure DevOps

1. Go to [Azure DevOps SSH Settings](https://dev.azure.com/_usersSettings/keys)
2. Click "Add"
3. Paste the **Ed25519 public key** content
4. Give it a descriptive name
5. Click "Save"

### GitLab

1. Go to [GitLab SSH Settings](https://gitlab.com/-/profile/keys)
2. Paste the **Ed25519 public key** content
3. Give it a descriptive title
4. Set expiration date (optional)
5. Click "Add key"

## Testing SSH Connection

After adding your public key to the Git provider:

```bash
# Test GitHub connection
ssh -T git@github.com

# Test Azure DevOps connection
ssh -T git@ssh.dev.azure.com

# Test GitLab connection
ssh -T git@gitlab.com
```

Expected response: `Hi yourusername! You've successfully authenticated...`

## Converting Repository to SSH

If your repository currently uses HTTPS, convert it to SSH:

```bash
# Check current remote URL
git remote -v

# Convert to SSH (replace with your actual repository)
git remote set-url origin git@github.com:yourusername/your-repo-name.git

# Verify the change
git remote -v
```

## SSH Configuration

The script creates an SSH config file (`~/.ssh/config`) that:

- Uses Ed25519 keys by default
- Configures common Git providers
- Enables SSH agent forwarding
- Sets proper identity files

## Troubleshooting

### "Permission denied (publickey)"

1. Verify the public key was added to your Git provider
2. Check SSH agent is running: `ssh-add -l`
3. Add key to agent: `ssh-add ~/.ssh/id_ed25519_yourusername`
4. Test connection: `ssh -T git@github.com`

### "Could not open a connection to your authentication agent"

```bash
# Start SSH agent
eval $(ssh-agent -s)

# Add your key
ssh-add ~/.ssh/id_ed25519_yourusername
```

### Key already exists

Use the `-Force` parameter to overwrite:

```powershell
.\scripts\setup-ssh-keys.ps1 -Force
```

## Security Best Practices

1. **Use Ed25519 keys** - More secure and faster than RSA
2. **Unique keys per user** - Don't share private keys
3. **Proper permissions** - SSH directory should be 700, keys should be 600
4. **Regular rotation** - Consider rotating keys annually
5. **Passphrase protection** - Add passphrases for additional security

## Key Formats

### Ed25519 Public Key Format

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your.email@example.com
```

### RSA Public Key Format

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... your.email@example.com
```

## Repository Integration

This SSH setup integrates with the Azure Cloud Things repository structure:

- **Infrastructure templates** can be cloned/pushed via SSH
- **Automation scripts** can reference SSH keys for remote operations
- **CI/CD pipelines** can use these keys for deployment authentication

## Support

For issues with SSH key setup:

1. Check [Git for Windows](https://git-scm.com/download/win) is installed
2. Verify OpenSSH is available: `ssh -V`
3. Review the [GitHub SSH documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---

**Author:** Jason Rinehart aka Technical Anxiety  
**Created:** 2025-01-01  
**Repository:** [Azure Cloud Things](https://github.com/yourusername/azure-cloud-things)
