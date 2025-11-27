<#
.SYNOPSIS
    Export Application Gateway HTTP listener names across all subscriptions

.DESCRIPTION
    This script discovers all Azure Application Gateways across all accessible
    subscriptions and exports their HTTP listener names to a text file. Useful for:
    - Application Gateway inventory and documentation
    - Listener configuration auditing
    - URL routing analysis
    - Migration planning
    - Compliance reporting
    
    The script:
    - Queries all accessible Azure subscriptions
    - Discovers all Application Gateways
    - Extracts HTTP listener names
    - Exports results to text file

.PARAMETER OutputPath
    Directory path where the output file will be saved (default: user's Documents folder)

.PARAMETER OutputFileName
    Name of the output file (default: "AppGatewayListeners.txt")

.PARAMETER SubscriptionFilter
    Optional subscription name pattern to filter (e.g., "prod*")

.EXAMPLE
    .\ta-get-appgateway-listeners.ps1
    
    Exports all Application Gateway listeners to Documents folder

.EXAMPLE
    .\ta-get-appgateway-listeners.ps1 -OutputPath "C:\Reports" -OutputFileName "AGW-Listeners.txt"
    
    Exports to custom location with custom filename

.EXAMPLE
    .\ta-get-appgateway-listeners.ps1 -SubscriptionFilter "prod*"
    
    Exports only from production subscriptions

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Az.Accounts module
    - Az.Network module
    - Reader access to subscriptions
    - Reader access to Application Gateways
    
    Impact: Provides visibility into Application Gateway listener configurations
    across entire Azure estate for documentation and auditing.

.VERSION
    2.0.0 - Complete rewrite with proper documentation and error handling
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added parameters, error handling, progress tracking, comprehensive documentation
    1.0.0 - Initial version with hardcoded paths
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = [Environment]::GetFolderPath("MyDocuments"),
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFileName = "AppGatewayListeners.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionFilter = "*"
)

# Initialize script
$ErrorActionPreference = "Stop"
$listenerCount = 0
$gatewayCount = 0
$subscriptionCount = 0

try {
    Write-Output "=========================================="
    Write-Output "Application Gateway Listener Export"
    Write-Output "=========================================="
    Write-Output "Start Time: $(Get-Date)"
    Write-Output "Output Path: $OutputPath"
    Write-Output ""

    # Verify Azure connection
    Write-Output "Verifying Azure connection..."
    $context = Get-AzContext
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    Write-Output "Connected as: $($context.Account.Id)"
    Write-Output ""

    # Get all accessible subscriptions
    Write-Output "Discovering subscriptions..."
    $allSubscriptions = Get-AzSubscription
    $subscriptions = $allSubscriptions | Where-Object { $_.Name -like $SubscriptionFilter }
    
    if ($subscriptions.Count -eq 0) {
        throw "No subscriptions found matching filter: $SubscriptionFilter"
    }
    
    Write-Output "Found $($subscriptions.Count) subscriptions matching filter"
    Write-Output ""

    # Initialize collections
    $listenerList = @()
    $gatewayDetails = @()

    # Process each subscription
    foreach ($sub in $subscriptions) {
        $subscriptionCount++
        Write-Output "[$subscriptionCount/$($subscriptions.Count)] Processing subscription: $($sub.Name)"
        Write-Output "----------------------------------------"
        
        try {
            # Set subscription context
            Set-AzContext -Subscription $sub.Name -InformationAction SilentlyContinue | Out-Null
            
            # Get all Application Gateways in subscription
            Write-Output "  Discovering Application Gateways..."
            $gwResources = Get-AzResource -ResourceType 'Microsoft.Network/applicationGateways' -ErrorAction SilentlyContinue
            
            if (-not $gwResources -or $gwResources.Count -eq 0) {
                Write-Output "  No Application Gateways found"
                Write-Output ""
                continue
            }
            
            Write-Output "  Found $($gwResources.Count) Application Gateway(s)"
            
            # Process each Application Gateway
            foreach ($gwRes in $gwResources) {
                try {
                    Write-Output "  Processing: $($gwRes.Name)"
                    
                    # Get full Application Gateway configuration
                    $gateway = Get-AzApplicationGateway -Name $gwRes.Name -ResourceGroupName $gwRes.ResourceGroupName `
                        -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    
                    if ($gateway) {
                        $gatewayCount++
                        
                        # Get HTTP listeners
                        $listeners = Get-AzApplicationGatewayHttpListener -ApplicationGateway $gateway `
                            -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                        
                        if ($listeners) {
                            foreach ($listener in $listeners) {
                                $listenerCount++
                                
                                # Add listener name to list
                                $listenerList += $listener.Name
                                
                                # Store detailed information
                                $gatewayDetails += [PSCustomObject]@{
                                    SubscriptionName = $sub.Name
                                    SubscriptionId = $sub.Id
                                    ResourceGroup = $gwRes.ResourceGroupName
                                    GatewayName = $gwRes.Name
                                    ListenerName = $listener.Name
                                    Protocol = $listener.Protocol
                                    Port = $listener.FrontendPort.Id.Split('/')[-1]
                                    HostName = $listener.HostName
                                }
                            }
                            
                            Write-Output "    Found $($listeners.Count) listener(s)"
                        } else {
                            Write-Output "    No listeners configured"
                        }
                    }
                    
                } catch {
                    Write-Warning "    Failed to process gateway $($gwRes.Name): $_"
                }
            }
            
        } catch {
            Write-Warning "  Error processing subscription $($sub.Name): $_"
        }
        
        Write-Output ""
    }

    # Export results
    Write-Output "Exporting results..."
    $outputFile = Join-Path $OutputPath $OutputFileName
    
    # Export listener names to text file
    $listenerList | Sort-Object -Unique | Out-File -FilePath $outputFile -Encoding UTF8
    
    # Also export detailed CSV for reference
    $csvFile = Join-Path $OutputPath "AppGatewayListeners-Details.csv"
    $gatewayDetails | Export-Csv -Path $csvFile -NoTypeInformation
    
    # Summary
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Export Summary"
    Write-Output "=========================================="
    Write-Output "Subscriptions Processed: $subscriptionCount"
    Write-Output "Application Gateways Found: $gatewayCount"
    Write-Output "Total Listeners Found: $listenerCount"
    Write-Output "Unique Listener Names: $(($listenerList | Sort-Object -Unique).Count)"
    Write-Output ""
    Write-Output "Output Files:"
    Write-Output "  Listener Names: $outputFile"
    Write-Output "  Detailed Report: $csvFile"
    Write-Output ""
    Write-Output "End Time: $(Get-Date)"
    Write-Output "=========================================="

    # Return summary object
    return @{
        SubscriptionCount = $subscriptionCount
        GatewayCount = $gatewayCount
        ListenerCount = $listenerCount
        OutputFile = $outputFile
        DetailedReport = $csvFile
        ExecutionTime = Get-Date
    }

} catch {
    Write-Error "Fatal error during Application Gateway listener export: $_"
    throw
}

<#
USAGE NOTES:

1. Prerequisites:
   - Install required modules:
     Install-Module -Name Az.Accounts, Az.Network
   - Connect to Azure: Connect-AzAccount
   - Ensure Reader access to subscriptions and Application Gateways

2. Common Use Cases:
   - Application Gateway inventory
   - Listener configuration documentation
   - URL routing analysis
   - Migration planning
   - Compliance auditing

3. Output Analysis:
   - Text file contains all listener names (one per line)
   - CSV file contains detailed information including:
     * Subscription and resource group
     * Gateway name
     * Listener name, protocol, port, hostname
   - Use for documentation or import into other tools

4. Integration:
   - Schedule via Azure Automation for regular inventory
   - Import into CMDB or documentation systems
   - Use with migration planning tools
   - Integrate with compliance reporting

5. Performance:
   - Processes multiple subscriptions sequentially
   - Large environments may take several minutes
   - Progress tracking shows current status

EXPECTED RESULTS:
- Text file with all listener names
- CSV file with detailed listener configuration
- Complete inventory of Application Gateway listeners
- Foundation for documentation and compliance

REAL-WORLD IMPACT:
Application Gateway listener inventory is essential for:
- Understanding application routing configuration
- Planning migrations or changes
- Documenting infrastructure
- Compliance and security audits
- Troubleshooting routing issues

Without this inventory:
- Manual documentation is time-consuming and error-prone
- Configuration drift goes unnoticed
- Migration planning is difficult
- Compliance gaps exist

With this inventory:
- Complete visibility into listener configuration
- Automated, up-to-date documentation
- Simplified migration planning
- Compliance verification

NEXT STEPS:
1. Review listener names for naming consistency
2. Verify listener configurations match standards
3. Document any non-standard configurations
4. Use for migration or consolidation planning
5. Schedule regular exports for ongoing documentation
#>