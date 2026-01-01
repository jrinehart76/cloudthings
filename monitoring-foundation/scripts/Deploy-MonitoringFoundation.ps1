<#
.SYNOPSIS
    Deploys the Monitoring Foundation to an Azure subscription.

.DESCRIPTION
    This script deploys the complete monitoring foundation including:
    - Log Analytics workspace with saved searches
    - Action groups for alert routing
    - Context-aware alert rules
    - Operational workbooks
    
    Supports validation-only mode for dry runs and handles existing resource updates.

.PARAMETER SubscriptionId
    Target Azure subscription ID.

.PARAMETER ResourceGroupName
    Resource group for monitoring resources. Will be created if it doesn't exist.

.PARAMETER Environment
    Environment identifier: dev, staging, or prod. Controls thresholds and severity.

.PARAMETER Location
    Azure region for resources. Defaults to East US.

.PARAMETER AlertEmailAddresses
    Array of email addresses for alert notifications.

.PARAMETER ItsmWebhookUrl
    Optional webhook URL for ITSM integration (ServiceNow, PagerDuty, etc.)

.PARAMETER ValidateOnly
    If specified, validates the deployment without making changes.

.EXAMPLE
    .\Deploy-MonitoringFoundation.ps1 -SubscriptionId "xxx" -ResourceGroupName "rg-monitoring" -Environment "prod" -AlertEmailAddresses @("oncall@company.com")

.EXAMPLE
    .\Deploy-MonitoringFoundation.ps1 -SubscriptionId "xxx" -ResourceGroupName "rg-monitoring" -Environment "dev" -ValidateOnly

.NOTES
    Author: Technical Anxiety
    Companion to: Beyond Azure Monitor series
    Repository: https://github.com/jrinehart76/cloudthings
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$Location = 'eastus',

    [Parameter(Mandatory = $false)]
    [string[]]$AlertEmailAddresses = @(),

    [Parameter(Mandatory = $false)]
    [string]$ItsmWebhookUrl = '',

    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Type = 'Info')
    
    $color = switch ($Type) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'Cyan' }
    }
    
    $prefix = switch ($Type) {
        'Success' { '[OK]' }
        'Warning' { '[WARN]' }
        'Error' { '[ERROR]' }
        default { '[INFO]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Status "Not connected to Azure. Connecting..." -Type Warning
            Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Status "Failed to connect to Azure: $($_.Exception.Message)" -Type Error
        return $false
    }
}

function Confirm-ResourceGroup {
    param([string]$Name, [string]$Location)
    
    $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
    
    if (-not $rg) {
        if ($ValidateOnly) {
            Write-Status "Resource group '$Name' would be created in '$Location'" -Type Info
        }
        else {
            Write-Status "Creating resource group '$Name' in '$Location'..." -Type Info
            New-AzResourceGroup -Name $Name -Location $Location | Out-Null
            Write-Status "Resource group created" -Type Success
        }
    }
    else {
        Write-Status "Resource group '$Name' exists" -Type Success
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Monitoring Foundation Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Display configuration
Write-Status "Configuration:"
Write-Host "  Subscription:    $SubscriptionId"
Write-Host "  Resource Group:  $ResourceGroupName"
Write-Host "  Environment:     $Environment"
Write-Host "  Location:        $Location"
Write-Host "  Email Addresses: $($AlertEmailAddresses -join ', ')"
Write-Host "  ITSM Webhook:    $(if ($ItsmWebhookUrl) { 'Configured' } else { 'Not configured' })"
Write-Host "  Mode:            $(if ($ValidateOnly) { 'Validation Only' } else { 'Deploy' })"
Write-Host ""

# Pre-flight checks
Write-Status "Running pre-flight checks..."

if (-not (Test-AzureConnection)) {
    exit 1
}

# Set subscription context
Write-Status "Setting subscription context..."
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Write-Status "Subscription context set" -Type Success

# Ensure resource group exists
Confirm-ResourceGroup -Name $ResourceGroupName -Location $Location

# Locate template files
$scriptRoot = $PSScriptRoot
$templatePath = Join-Path (Split-Path $scriptRoot -Parent) "main.bicep"
$parametersPath = Join-Path (Split-Path $scriptRoot -Parent) "examples/parameters.$Environment.json"

if (-not (Test-Path $templatePath)) {
    Write-Status "Template file not found: $templatePath" -Type Error
    exit 1
}

# Build parameters
$deploymentParams = @{
    ResourceGroupName = $ResourceGroupName
    TemplateFile      = $templatePath
    environment       = $Environment
    location          = $Location
    alertEmailAddresses = $AlertEmailAddresses
}

if ($ItsmWebhookUrl) {
    $deploymentParams.itsmWebhookUrl = $ItsmWebhookUrl
}

# Execute deployment
Write-Host ""
if ($ValidateOnly) {
    Write-Status "Validating deployment..."
    
    try {
        $validation = Test-AzResourceGroupDeployment @deploymentParams
        
        if ($validation) {
            Write-Status "Validation failed:" -Type Error
            $validation | ForEach-Object {
                Write-Host "  - $($_.Message)" -ForegroundColor Red
            }
            exit 1
        }
        else {
            Write-Status "Validation successful - deployment would succeed" -Type Success
        }
    }
    catch {
        Write-Status "Validation error: $($_.Exception.Message)" -Type Error
        exit 1
    }
}
else {
    Write-Status "Starting deployment..."
    
    try {
        $deploymentName = "monitoring-foundation-$Environment-$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        $deployment = New-AzResourceGroupDeployment @deploymentParams `
            -Name $deploymentName `
            -Verbose
        
        if ($deployment.ProvisioningState -eq 'Succeeded') {
            Write-Host ""
            Write-Status "Deployment successful!" -Type Success
            Write-Host ""
            Write-Host "Deployed Resources:" -ForegroundColor Cyan
            Write-Host "  Workspace ID:     $($deployment.Outputs.workspaceId.Value)"
            Write-Host "  Workspace Name:   $($deployment.Outputs.workspaceName.Value)"
            Write-Host "  Action Group ID:  $($deployment.Outputs.actionGroupId.Value)"
            Write-Host "  Alert Rules:      $($deployment.Outputs.alertRuleNames.Value -join ', ')"
            Write-Host "  Workbook ID:      $($deployment.Outputs.workbookId.Value)"
        }
        else {
            Write-Status "Deployment finished with state: $($deployment.ProvisioningState)" -Type Warning
        }
    }
    catch {
        Write-Status "Deployment failed: $($_.Exception.Message)" -Type Error
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""