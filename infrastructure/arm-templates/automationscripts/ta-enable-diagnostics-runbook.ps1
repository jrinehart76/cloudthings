<#
.SYNOPSIS
    Enables diagnostic settings for Azure resources via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook enables diagnostic settings for Azure resources
    to send logs and metrics to a Log Analytics workspace. The runbook:
    
    - Discovers all resources in the subscription or specific resource group
    - Validates the Log Analytics workspace exists
    - Checks if diagnostic settings are already configured
    - Enables diagnostic settings with default log and metric categories
    - Skips resources that don't support diagnostic settings
    - Avoids overwriting existing diagnostic configurations
    
    Diagnostic settings provide:
    - Centralized logging for compliance and auditing
    - Performance metrics for monitoring and alerting
    - Security event logs for threat detection
    - Operational logs for troubleshooting
    
    The runbook uses a standardized diagnostic setting name ("diagnostics") to
    maintain consistency across the environment.
    
    Designed for scheduled execution in Azure Automation to maintain compliance.

.PARAMETER WorkspaceName
    The name of the Log Analytics workspace where diagnostic logs will be sent.
    The workspace must already exist in the subscription.
    
    Example: 'laws-prod-eastus'

.PARAMETER ResourceGroupName
    Optional. The name of a specific resource group to target.
    If not specified, the runbook will process all resources in the subscription.
    
    Example: 'rg-production-resources'

.EXAMPLE
    # Enable diagnostics for all resources in subscription
    .\ta-enable-diagnostics-runbook.ps1 -WorkspaceName 'laws-prod-eastus'

.EXAMPLE
    # Enable diagnostics for resources in a specific resource group
    .\ta-enable-diagnostics-runbook.ps1 -WorkspaceName 'laws-prod-eastus' -ResourceGroupName 'rg-production-resources'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account with Run As Account (Service Principal) configured
    - Service Principal must have Contributor or Monitoring Contributor role
    - Required PowerShell modules in Automation Account:
      * Az.Accounts
      * Az.Resources
      * Az.OperationalInsights
      * Az.Monitor
    - Log Analytics workspace must exist and be accessible
    
    Resource Support:
    - Not all Azure resource types support diagnostic settings
    - Resources that don't support diagnostics will be skipped automatically
    - Common supported types: Storage Accounts, Key Vaults, SQL Databases, App Services, etc.
    
    Diagnostic Setting Name: "diagnostics" (standardized)
    
    Future Enhancements:
    - Add tag-based filtering to target specific resources
    - Add support for custom log/metric category selection
    
    Impact: Ensures comprehensive diagnostic logging across Azure resources for
    compliance, security monitoring, troubleshooting, and performance analysis.
    Essential for meeting audit requirements and maintaining operational visibility.

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - 2019-07-02 - Initial version
#>

param (
    [Parameter(Mandatory=$True, HelpMessage="Name of the Log Analytics workspace")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,
    
    [Parameter(Mandatory=$False, HelpMessage="Optional resource group name to limit scope")]
    [string]$ResourceGroupName
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all resources
$DiagnosticSettingName = "diagnostics"
$successCount = 0
$failureCount = 0
$alreadyConfiguredCount = 0
$unsupportedCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Enable Diagnostic Settings Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Log Analytics Workspace: $WorkspaceName"
if ($ResourceGroupName) {
    Write-Output "Target Resource Group: $ResourceGroupName"
} else {
    Write-Output "Target Scope: All resources in subscription"
}
Write-Output ""

# Connect to Azure using Automation Account Run As Connection
Write-Output "Connecting to Azure..."
$ConnectionName = 'AzureRunAsConnection'

Try {
    # Get the automation connection asset
    $AutomationConnection = Get-AutomationConnection -Name $ConnectionName
    
    # Connect to Azure with the service principal
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal `
        -ErrorAction Stop
    
    # Get subscription context
    $context = Get-AzContext
    Write-Output "Connected to Azure"
    Write-Output "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
    Write-Output "Service Principal: $($AutomationConnection.ApplicationId)"
    Write-Output ""
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection '$ConnectionName' not found. Ensure the Automation Account has a Run As Account configured."
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
    else {
        Write-Error "Failed to connect to Azure: $_"
        throw $_.Exception
    }
}

# Get Log Analytics workspace
Write-Output "Retrieving Log Analytics workspace..."
Try {
    $Workspace = Get-AzOperationalInsightsWorkspace -ErrorAction Stop | 
        Where-Object {$_.Name -eq $WorkspaceName}
    
    if (!$Workspace) {
        Write-Error "Log Analytics workspace '$WorkspaceName' not found in subscription."
        throw "Workspace not found"
    }
    
    Write-Output "Workspace: $($Workspace.Name)"
    Write-Output "Resource Group: $($Workspace.ResourceGroupName)"
    Write-Output "Workspace ID: $($Workspace.ResourceId)"
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve workspace: $_"
    throw
}

# Get list of resources based on scope
Write-Output "Discovering resources..."
Try {
    if ($ResourceGroupName) {
        $Resources = Get-AzResource -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        Write-Output "Found $($Resources.Count) resources in resource group: $ResourceGroupName"
    }
    else {
        $Resources = Get-AzResource -ErrorAction Stop
        Write-Output "Found $($Resources.Count) resources in subscription"
    }
    Write-Output ""
}
Catch {
    Write-Error "Failed to retrieve resources: $_"
    throw
}

# Validate resources were found
if (!($Resources) -or $Resources.Count -eq 0) {
    Write-Output "No resources found in the specified scope. Exiting."
    return
}

# Process each resource to enable diagnostic settings
Write-Output "Processing resources for diagnostic settings..."
$count = 0
ForEach ($Resource in $Resources) {
    $count++
    
    # Show progress every 50 resources
    if ($count % 50 -eq 0) {
        Write-Output "  Progress: $count/$($Resources.Count) resources processed..."
    }
    
    Try {
        # Check if diagnostic settings already exist on this resource
        $DiagnosticSettings = Get-AzDiagnosticSetting -ResourceId $Resource.ResourceId -ErrorAction 'Stop'
        
        if (!($DiagnosticSettings)) {
            # No diagnostic settings exist - enable with default categories
            Try {
                Set-AzDiagnosticSetting -Name $DiagnosticSettingName `
                    -WorkspaceId $Workspace.ResourceId `
                    -ResourceId $Resource.ResourceId `
                    -Enabled $True `
                    -ErrorAction 'Stop' | Out-Null
                
                Write-Output "  ✓ Enabled diagnostics: $($Resource.Name) ($($Resource.ResourceType))"
                $successCount++
            }
            Catch {
                Write-Warning "  ✗ Failed to enable diagnostics on $($Resource.Name): $_"
                $failureCount++
            }
        } else {
            # Diagnostic settings already exist - don't overwrite
            $alreadyConfiguredCount++
        }
    }
    Catch {
        # Resource doesn't support diagnostic settings or other error
        if ($_.Exception.ToString().Contains("BadRequest") -or 
            $_.Exception.ToString().Contains("not support") -or
            $_.Exception.ToString().Contains("ResourceNotSupported")) {
            # Resource type doesn't support diagnostic settings - this is expected
            $unsupportedCount++
        }
        else {
            # Unexpected error
            Write-Warning "  ✗ Error processing $($Resource.Name): $_"
            $failureCount++
        }
    }
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total Resources Processed: $($Resources.Count)"
Write-Output "Successfully Enabled: $successCount"
Write-Output "Already Configured: $alreadyConfiguredCount"
Write-Output "Unsupported Resource Types: $unsupportedCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="
