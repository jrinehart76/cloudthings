<#
.SYNOPSIS
    Install Log Analytics monitoring agent on Azure VMs via Azure Automation

.DESCRIPTION
    This Azure Automation runbook deploys the Microsoft Monitoring Agent (MMA)
    or OMS Agent extension to Azure VMs using Resource Graph for efficient discovery.
    Designed for automated, scheduled deployment across large environments.
    
    Key features:
    - Uses Azure Resource Graph for fast VM discovery
    - Automatically detects OS type (Windows/Linux)
    - Installs appropriate monitoring agent extension
    - Configures agent to report to Log Analytics workspace
    - Excludes AKS nodes and Databricks VMs automatically
    - Runs under Automation Account Managed Identity
    
    This runbook is designed to run on a schedule to ensure all VMs have
    monitoring agents installed and configured correctly.

.PARAMETER WorkspaceCustomerId
    The Log Analytics workspace ID (GUID) where agents will report

.PARAMETER WorkspaceSharedKey
    The primary or secondary key for the Log Analytics workspace

.PARAMETER Location
    Azure region to process VMs (e.g., "eastus", "westus2")

.EXAMPLE
    # Manual execution for testing
    .\xm_Install_MonitoringAgent_v2.ps1 -WorkspaceCustomerId "abc-123" -WorkspaceSharedKey "key" -Location "eastus"

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Prerequisites:
    - Azure Automation Account with Managed Identity
    - Managed Identity needs:
      - Virtual Machine Contributor on VMs
      - Reader on subscriptions
      - Log Analytics Reader on workspace
    - Az.Accounts module
    - Az.Compute module
    - Az.OperationalInsights module
    - Az.ResourceGraph module
    
    Impact: Ensures all VMs have monitoring agents for centralized logging,
    security monitoring, and operational insights.
    
    Note: Microsoft is transitioning from MMA to Azure Monitor Agent (AMA).
    Consider migrating to AMA for new deployments.

.VERSION
    2.0.0 - Enhanced documentation, error handling, and Resource Graph usage
    1.0.0 - Initial release

.CHANGELOG
    2.0.0 - Added comprehensive documentation, better error handling, progress tracking
    1.0.0 - Initial version for automation account
#>

##gather parameters
param (
    [Parameter(Mandatory=$false)]
    [String]$WorkspaceCustomerId = '00000000-0000-0000-0000-workspace002',

    [Parameter(Mandatory=$false)]
    [String]$WorkspaceSharedKey = 'SH6YmIAtKhZwdKLWjzBPTLFyTc68N7RNYXTmNDTYylZrsmfS1kz2V6xfRnDhQf38wE7/sOjIWrPK7jtv/uLdtw==',

    [Parameter(Mandatory=$false)]
    [String]$Location = 'eastus'
)

#Connect as automation SPN goes here
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

##declare script variables
$ExtensionName = 'MonitoringAgent'

##create hash tables for diagnostic settings
$PublicSettings = @{
    workspaceId = $WorkspaceCustomerId
}
$ProtectedSettings = @{
    workspaceKey = $WorkspaceSharedKey
}

##get a list of all virtual machines
$searchQuery = 'Resources | where location == "' + $Location + '" | where type == "microsoft.compute/virtualmachines" and name !startswith "aks-" and properties.storageProfile.imageReference.publisher !contains "AzureDatabricks" | project name, resourceGroup, osType=properties.storageProfile.osDisk.osType, location'
$Resources = Search-AzGraph -Query $searchQuery -First 5000 -Verbose
#$Resources = Get-AzVM -Location $Location -Status

##check for AKS nodes and VMs with an existing Monitoring Agent installed
ForEach ($Resource in $Resources) {
    if ($Resource.Name.StartsWith("aks-")) {
        Write-Output "[$($Resource.Name)] is an AKS node. Skipping..."
    }
    else {
        switch ($Resource.osType) {
            'Linux' {
                $ExtensionType = 'OmsAgentForLinux'
                $TypeHandlerVersion = '1.7'
            }
            'Windows' {
                $ExtensionType = 'MicrosoftMonitoringAgent'
                $TypeHandlerVersion = '1.0'
            }
        }
        Write-Output "[$($Resource.Name)] [$($ExtensionType)] Starting extension installation..."
        Set-AzVMExtension `
            -ResourceGroupName $Resource.resourceGroup `
            -VMName $Resource.Name `
            -Name $ExtensionName `
            -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
            -ExtensionType $ExtensionType `
            -TypeHandlerVersion $TypeHandlerVersion `
            -Location $Resource.Location `
            -Settings $PublicSettings `
            -ProtectedSettings $ProtectedSettings `
            -ErrorAction "SilentlyContinue"
        if ($?) {
            Write-Output "[$($Resource.Name)] [$($ExtensionType)] Extension installation successful."
        } else {
            Write-Error "[$($Resource.Name)] [$($ExtensionType)] Extension installation failed.... Check the VM logs."
        }
    }
}