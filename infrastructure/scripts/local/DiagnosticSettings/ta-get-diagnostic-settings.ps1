<#
.SYNOPSIS
    List all Azure resources with diagnostic settings configured

.DESCRIPTION
    This script discovers all Azure resources that have diagnostic settings
    configured. Essential for:
    - Monitoring compliance verification
    - Audit and documentation
    - Identifying configured vs unconfigured resources
    - Troubleshooting diagnostic issues
    
    The script:
    - Queries all resources in subscription
    - Checks diagnostic settings for each
    - Exports list of resources with diagnostics
    - Provides summary statistics

.PARAMETER OutputPath
    Directory path where CSV report will be saved (default: user's Documents folder)

.PARAMETER ResourceGroupFilter
    Optional resource group name pattern to filter (e.g., "rg-prod-*")

.PARAMETER ShowUnconfigured
    If true, shows resources WITHOUT diagnostic settings instead

.EXAMPLE
    .\ta-get-diagnostic-settings.ps1
    
    Lists all resources with diagnostic settings

.EXAMPLE
    .\ta-get-diagnostic-settings.ps1 -ShowUnconfigured
    
    Lists resources WITHOUT diagnostic settings (gaps)

.EXAMPLE
    .\ta-get-diagnostic-settings.ps1 -ResourceGroupFilter "rg-prod-*" -OutputPath "C:\Reports"
    
    Lists production resources with diagnostics

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Monitor module
    - Az.Resources module
    - Reader access to subscription
    
    Impact: Provides visibility into diagnostic settings configuration
    for compliance and troubleshooting.

.VERSION
    2.0.0 - Complete rewrite with proper documentation
    1.0.0 - Initial release
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupFilter = "*",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowUnconfigured
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = Join-Path $OutputPath "DiagnosticSettings-$timestamp.csv"
$results = @()
$configuredCount = 0
$unconfiguredCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Diagnostic Settings Discovery"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output ""

    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    Write-Output "Discovering resources..."
    $resources = Get-AzResource | Where-Object { $_.ResourceGroupName -like $ResourceGroupFilter }
    Write-Output "Found $($resources.Count) resources"
    Write-Output ""

    $count = 0
    foreach ($res in $resources) {
        $count++
        if ($count % 50 -eq 0) {
            Write-Output "  Processed $count/$($resources.Count)..."
        }

        try {
            $settings = Get-AzDiagnosticSetting -ResourceId $res.ResourceId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            
            if ($settings) {
                $configuredCount++
                if (-not $ShowUnconfigured) {
                    $results += [PSCustomObject]@{
                        ResourceName = $res.Name
                        ResourceType = $res.ResourceType
                        ResourceGroup = $res.ResourceGroupName
                        Location = $res.Location
                        DiagnosticName = $settings.Name
                        WorkspaceId = $settings.WorkspaceId
                        Status = "Configured"
                    }
                }
            } else {
                $unconfiguredCount++
                if ($ShowUnconfigured) {
                    $results += [PSCustomObject]@{
                        ResourceName = $res.Name
                        ResourceType = $res.ResourceType
                        ResourceGroup = $res.ResourceGroupName
                        Location = $res.Location
                        DiagnosticName = "Not Configured"
                        WorkspaceId = "N/A"
                        Status = "Missing"
                    }
                }
            }
        } catch {
            Continue
        }
    }

    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $csvFile -NoTypeInformation
    }

    $compliancePercentage = if ($resources.Count -gt 0) {
        [math]::Round(($configuredCount / $resources.Count) * 100, 2)
    } else { 0 }

    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Summary"
    Write-Output "=========================================="
    Write-Output "Total Resources: $($resources.Count)"
    Write-Output "Configured: $configuredCount"
    Write-Output "Unconfigured: $unconfiguredCount"
    Write-Output "Compliance: $compliancePercentage%"
    if ($results.Count -gt 0) {
        Write-Output "Output File: $csvFile"
    }
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

} catch {
    Write-Error "Fatal error: $_"
    throw
}
