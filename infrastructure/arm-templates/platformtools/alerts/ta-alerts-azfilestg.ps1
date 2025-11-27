<#
.SYNOPSIS
    Deploys Azure File Share capacity monitoring alerts.

.DESCRIPTION
    This script deploys Azure Monitor metric alerts for Azure File Share capacity monitoring.
    It automatically discovers all storage accounts and creates capacity alerts for each.
    
    Monitors: File share capacity thresholds, storage quota usage
    Essential for: Preventing storage exhaustion, capacity planning, avoiding service disruptions

.PARAMETER threshold
    Capacity threshold percentage for alerting (e.g., '80' for 80%)

.PARAMETER version
    Alert rule version

.PARAMETER severity
    Alert severity level (default: '2' for critical)

.PARAMETER subscriptionid
    Azure subscription ID

.PARAMETER agResourceGroup
    Resource group containing action groups

.PARAMETER deployResourceGroup
    Resource group where alerts will be deployed

.EXAMPLE
    .\ta-alerts-azfilestg.ps1 -threshold '80' -version 'v1' -subscriptionid '12345' -agResourceGroup 'rg-monitoring' -deployResourceGroup 'rg-alerts'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Last Updated: 2025-01-15
    Prerequisites: Storage accounts, action group MSP-alert-exec-s2
    Impact: Prevents file share capacity exhaustion and service disruptions

.VERSION
    2.0.0
#>

param (
    [Parameter(Mandatory=$true, HelpMessage="Capacity threshold percentage")]
    [ValidateNotNullOrEmpty()]
    [string]$threshold,

    [Parameter(Mandatory=$true, HelpMessage="Alert version")]
    [ValidateNotNullOrEmpty()]
    [string]$version,
    
    [Parameter(Mandatory=$false)]
    [string]$severity = '2',

    [Parameter(Mandatory=$true, HelpMessage="Subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]$subscriptionid,

    [Parameter(Mandatory=$true, HelpMessage="Action group resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$agResourceGroup,

    [Parameter(Mandatory=$true, HelpMessage="Deployment resource group")]
    [ValidateNotNullOrEmpty()]
    [string]$deployResourceGroup
)

Write-Output "=========================================="
Write-Output "Deploy Azure File Share Capacity Alerts"
Write-Output "=========================================="
Write-Output "Threshold: $threshold%"
Write-Output "Severity: $severity"
Write-Output ""

$actionGroupS2 = "/subscriptions/$subscriptionid/resourceGroups/$agResourceGroup/providers/microsoft.insights/actionGroups/MSP-alert-exec-s2"

Write-Output "Discovering storage accounts..."
$storageList = Get-AzStorageAccount
Write-Output "Found $($storageList.Count) storage accounts"
Write-Output ""

$count = 0
foreach ($storage in $storageList) {
    $count++
    Write-Output "[$count/$($storageList.Count)] Deploying alert for: $($storage.StorageAccountName)"
    Try {
        New-AzResourceGroupDeployment `
            -Name "deploy-azure-fileshare-critical-alert-$($storage.StorageAccountName)" `
            -ResourceGroupName $deployResourceGroup `
            -TemplateFile ./alert.critical.azfilecapacity.json `
            -threshold $threshold `
            -location $storage.Location `
            -storage $storage.StorageAccountName `
            -version $version `
            -severity $severity `
            -actionGroup $actionGroupS2 `
            -subscriptionId $subscriptionid `
            -storageResourceGroup $storage.ResourceGroupName `
            -ErrorAction Stop | Out-Null
        Write-Output "  ✓ Alert deployed"
    }
    Catch {
        Write-Warning "  ✗ Failed: $_"
    }
}

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Complete"
Write-Output "=========================================="
Write-Output "Processed $($storageList.Count) storage accounts"
Write-Output "=========================================="
