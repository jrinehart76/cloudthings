<#
.SYNOPSIS
    Configure diagnostic settings to send logs to Event Hub

.DESCRIPTION
    This script configures diagnostic settings for Azure resources to send
    logs and metrics to an Event Hub. Essential for:
    - Real-time log streaming to external systems
    - Integration with SIEM solutions
    - Custom log processing pipelines
    - Compliance and audit log forwarding
    
    Real-world impact: Enables real-time log streaming for security
    monitoring, compliance, and integration with external systems.

.PARAMETER tagName
    Optional tag name to filter resources

.PARAMETER tagValue
    Optional tag value to filter resources

.PARAMETER subscriptionId
    Azure subscription ID

.PARAMETER hubName
    Name of the Event Hub to send logs to

.PARAMETER hubRG
    Resource group containing the Event Hub

.PARAMETER hubNamespace
    Event Hub namespace name

.PARAMETER throttle
    Maximum number of parallel configuration jobs (default: 5)

.EXAMPLE
    .\ta-set-diagnostics-hub.ps1 -subscriptionId "12345" -hubName "insights-logs" -hubRG "rg-monitoring" -hubNamespace "prod-eh-eastus"

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Monitor module
    - Monitoring Contributor role
    - Event Hub must exist
    
    Impact: Enables real-time log streaming to Event Hub for
    SIEM integration and custom processing.

.VERSION
    2.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$tagName,
    
    [Parameter(Mandatory=$false)]
    [string]$tagValue,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$hubName,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$hubRG,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$hubNamespace,
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 20)]
    [int]$throttle = 5
)

# Initialize script
$ErrorActionPreference = "Continue"
$jobs = @()
$configuredCount = 0
$skippedCount = 0
$errorCount = 0
$resources = @()

try {
    Write-Output "=========================================="
    Write-Output "Configure Diagnostic Settings - Event Hub"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Event Hub: $hubName"
    Write-Output "Namespace: $hubNamespace"
    Write-Output ""

    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    $diagnosticSettingName = "diagnosticsHub"
    $authorizationId = "/subscriptions/$subscriptionId/resourceGroups/$hubRG/providers/Microsoft.EventHub/namespaces/$hubNamespace/authorizationrules/RootManageSharedAccessKey"

    # Discover resources
    if ($tagValue -and $tagName) {
        Write-Output "Filter: Tag '$tagName' = '$tagValue'"
        $tagTable = @{$tagName = $tagValue}
        $resourceGroups = Get-AzResourceGroup -Tag $tagTable
        
        foreach ($resourceGroup in $resourceGroups) {
            $list = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
            if ($list) {
                $resources += $list
            }
        }
    } else {
        Write-Output "Filter: All resources"
        $resources = Get-AzResource
    }

    Write-Output "Found $($resources.Count) resource(s)"
    Write-Output ""

    $SetAzDiagnosticSettingsJob = {
        param ($diagnosticSettingName, $authorizationId, $hubName, $resourceId, $resourceName)
        
        try {
            Set-AzDiagnosticSetting -Name $diagnosticSettingName `
                -EventHubName $hubName `
                -EventHubAuthorizationRuleId $authorizationId `
                -ResourceId $resourceId `
                -Enabled $true `
                -ErrorAction Stop `
                -WarningAction SilentlyContinue | Out-Null
            
            return @{ Success = $true; ResourceName = $resourceName }
        } catch {
            return @{ Success = $false; ResourceName = $resourceName; Error = $_.Exception.Message }
        }
    }

    $count = 0
    foreach ($resource in $resources) {
        $count++
        
        if ($count % 50 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }
        
        try {
            $diagSetting = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId `
                -ErrorAction Stop -WarningAction SilentlyContinue
            
            if (-not $diagSetting.EventHubAuthorizationRuleId) {
                $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
                if ($runningJobs.Count -ge $throttle) {
                    $runningJobs | Wait-Job -Any | Out-Null
                }
                
                $jobs += Start-Job -ScriptBlock $SetAzDiagnosticSettingsJob `
                    -ArgumentList $diagnosticSettingName, $authorizationId, $hubName, $resource.ResourceId, $resource.Name
            } else {
                $skippedCount++
            }
        } catch {
            if (-not $_.Exception.ToString().Contains("BadRequest")) {
                $errorCount++
            }
        }
    }

    if ($jobs.Count -gt 0) {
        Write-Output ""
        Write-Output "Waiting for configuration jobs to complete..."
        $jobs | Wait-Job | Out-Null
        
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            if ($result.Success) {
                $configuredCount++
            } else {
                Write-Warning "  [$($result.ResourceName)] FAILED - $($result.Error)"
                $errorCount++
            }
        }
        
        $jobs | Remove-Job
    }

    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Configuration Summary"
    Write-Output "=========================================="
    Write-Output "Total Resources: $($resources.Count)"
    Write-Output "Configured: $configuredCount"
    Write-Output "Already Configured: $skippedCount"
    Write-Output "Errors: $errorCount"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    return @{
        TotalResources = $resources.Count
        ConfiguredCount = $configuredCount
        SkippedCount = $skippedCount
        ErrorCount = $errorCount
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error: $_"
    if ($jobs) {
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -ErrorAction SilentlyContinue
    }
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install: Install-Module -Name Az.Monitor
   - Connect: Connect-AzAccount
   - Event Hub must exist
   - Ensure Monitoring Contributor role

2. Event Hub Benefits:
   - Real-time log streaming
   - SIEM integration (Splunk, QRadar, etc.)
   - Custom log processing
   - Compliance log forwarding
   - Low latency (seconds vs. minutes)

3. Use Cases:
   - Security monitoring with SIEM
   - Real-time alerting systems
   - Custom log analytics
   - Compliance audit trails
   - Integration with external systems

4. Cost Considerations:
   - Event Hub throughput units
   - Data ingress charges
   - Balance with Log Analytics for cost optimization

NEXT STEPS:
1. Verify logs flowing to Event Hub
2. Configure downstream consumers
3. Set up retention policies
4. Monitor Event Hub metrics
#>
