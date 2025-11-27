<#
.SYNOPSIS
    Configures diagnostic settings for Azure resources via Azure Automation runbook.

.DESCRIPTION
    This Azure Automation runbook enables or reconfigures diagnostic settings for all 
    supported Azure resources in a specified location. It ensures consistent diagnostic 
    configuration across the environment by:
    
    - Discovering all resources in the target location using Azure Resource Graph
    - Checking existing diagnostic settings
    - Creating standardized diagnostic settings if missing
    - Updating non-standard diagnostic settings to match platform standards
    - Sending all logs and metrics to a centralized Log Analytics workspace
    
    The runbook automatically excludes compute resources, insights, and management resources
    to focus on infrastructure and platform services that benefit most from centralized logging.
    
    This is designed for scheduled execution in Azure Automation to maintain compliance
    with diagnostic logging standards across the environment.

.PARAMETER location
    The Azure region to target for diagnostic configuration.
    Examples: 'eastus', 'westus2', 'southcentralus'
    Default: 'eastus'

.PARAMETER workspaceId
    The full resource ID of the Log Analytics workspace where diagnostic logs will be sent.
    Format: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}
    
    Note: Update the default value to match your environment's Log Analytics workspace.

.EXAMPLE
    # Run with default location (eastus) and default workspace
    .\ta-configure-diagnostics-runbook.ps1

.EXAMPLE
    # Configure diagnostics for resources in West US 2
    .\ta-configure-diagnostics-runbook.ps1 -location 'westus2'

.EXAMPLE
    # Configure with custom workspace
    .\ta-configure-diagnostics-runbook.ps1 -location 'eastus' -workspaceId '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/laws-prod'

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
      * Az.ResourceGraph
      * Az.Monitor
    - Log Analytics workspace must exist and be accessible
    
    Impact: Ensures comprehensive diagnostic logging for compliance, troubleshooting,
    and security monitoring. Centralizes logs for easier analysis and alerting.
    
    Diagnostic Setting Name: PLATFORMDiagnosticsLog (standardized across environment)

.VERSION
    2.0.0 - Enhanced documentation and error handling

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation, improved error handling, added progress tracking
    1.0.0 - 2020-01-21 - Initial version
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$location = 'eastus',

    [Parameter(Mandatory = $false)]
    [string]$workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-am-eastus/providers/Microsoft.OperationalInsights/workspaces/laws-am-eastus'
)

# Initialize script variables
$ErrorActionPreference = "Continue"  # Continue on errors to process all resources
$requiredDiagnosticName = "PLATFORMDiagnosticsLog"
$successCount = 0
$failureCount = 0
$alreadyConfiguredCount = 0

# Output runbook start information
Write-Output "=========================================="
Write-Output "Configure Diagnostic Settings Runbook"
Write-Output "=========================================="
Write-Output "Start Time: $(Get-Date)"
Write-Output "Target Location: $location"
Write-Output "Target Workspace: $workspaceId"
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

# Query Azure Resource Graph for resources in the target location
# Exclude compute, insights, operations management, workspaces, and route tables
Write-Output "Querying resources in location: $location"
$searchQuery = @"
Resources 
| where location == '$location' 
| where type !contains 'microsoft.compute' 
    and type !contains 'microsoft.operationsmanagement' 
    and type !contains 'microsoft.insights' 
    and type !contains 'workspaces' 
    and type !contains 'routetables'
| project name, id, type, resourceGroup
"@

Try {
    $resources = Search-AzGraph -Query $searchQuery -First 5000
    Write-Output "Found $($resources.Count) resources to process"
    Write-Output ""
}
Catch {
    Write-Error "Failed to query Azure Resource Graph: $_"
    throw
}

# Process each resource to configure diagnostic settings
$count = 0
ForEach ($resource in $resources) {
    $count++
    
    # Show progress every 50 resources
    if ($count % 50 -eq 0) {
        Write-Output "  Progress: $count/$($resources.Count) resources processed..."
    }
    
    Try {
        # Check if diagnostic settings already exist on this resource
        $DiagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.id -ErrorAction 'SilentlyContinue' -WarningAction 'SilentlyContinue'
        
        if (!($DiagnosticSettings)) {
            # No diagnostic settings exist - create new one
            Set-AzDiagnosticSetting -Name $requiredDiagnosticName `
                -WorkspaceId $workspaceId `
                -ResourceId $resource.id `
                -Enabled $True `
                -ErrorAction 'Stop' `
                -WarningAction 'SilentlyContinue' | Out-Null
        
            Write-Output "  ✓ Enabled diagnostics on: $($resource.name) ($($resource.type))"
            $successCount++
        }
        elseif ($DiagnosticSettings -and ($DiagnosticSettings.Name -ne $requiredDiagnosticName)) {
            # Diagnostic settings exist but with wrong name - update to standard
            Remove-AzDiagnosticSetting -ResourceId $resource.id `
                -Name $DiagnosticSettings.Name `
                -WarningAction 'SilentlyContinue' `
                -ErrorAction 'SilentlyContinue' | Out-Null
                        
            Set-AzDiagnosticSetting -Name $requiredDiagnosticName `
                -WorkspaceId $workspaceId `
                -ResourceId $resource.id `
                -Enabled $True `
                -ErrorAction 'Stop' `
                -WarningAction 'SilentlyContinue' | Out-Null
                
            Write-Output "  ✓ Updated diagnostics on: $($resource.name) (was: $($DiagnosticSettings.Name))"
            $successCount++
        }
        else {
            # Diagnostic settings already correctly configured
            $alreadyConfiguredCount++
        }
    }
    Catch {
        # Some resources don't support diagnostic settings or have permission issues
        Write-Warning "  ✗ Cannot configure diagnostics on: $($resource.name) - $_"
        $failureCount++
    }
    finally {
        # Clean up variables to prevent memory issues in long-running runbooks
        if ($DiagnosticSettings) {
            Clear-Variable -Name 'DiagnosticSettings' -ErrorAction SilentlyContinue
        }
    }
}

# Output summary statistics
Write-Output ""
Write-Output "=========================================="
Write-Output "Summary"
Write-Output "=========================================="
Write-Output "Total Resources Processed: $($resources.Count)"
Write-Output "Successfully Configured: $successCount"
Write-Output "Already Configured: $alreadyConfiguredCount"
Write-Output "Failed: $failureCount"
Write-Output ""
Write-Output "End Time: $(Get-Date)"
Write-Output "=========================================="