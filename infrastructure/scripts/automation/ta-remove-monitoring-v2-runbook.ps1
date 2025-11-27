<#
.SYNOPSIS
    Removes Log Analytics monitoring agents from VMs connected to different workspaces.

.DESCRIPTION
    This Azure Automation runbook removes Log Analytics monitoring agents (MMA/OMS) from
    virtual machines that are connected to a different workspace than specified. This is
    useful for workspace migration scenarios. The runbook:
    
    - Discovers all VMs in the target location
    - Checks each VM for existing monitoring agent
    - Compares the configured workspace ID with the target workspace
    - Removes agents connected to different workspaces
    - Skips VMs already connected to the correct workspace
    - Automatically skips AKS nodes (managed by AKS)
    
    Use Case: Workspace consolidation or migration where VMs need to be moved from
    one Log Analytics workspace to another. Run this script first to remove old agents,
    then run the install script to add agents for the new workspace.
    
    Designed for scheduled execution in Azure Automation.

.PARAMETER WorkspaceCustomerId
    The workspace ID (customer ID) of the target workspace.
    VMs connected to this workspace will be skipped.
    VMs connected to different workspaces will have their agents removed.
    
    Format: GUID (e.g., '12345678-1234-1234-1234-123456789012')

.PARAMETER Location
    The Azure region to target for VM discovery.
    Only VMs in this location will be processed.
    
    Example: 'eastus', 'westus2', 'southcentralus'

.EXAMPLE
    # Remove agents from VMs not connected to the target workspace in East US
    .\ta-remove-monitoring-v2-runbook.ps1 -WorkspaceCustomerId '12345678-1234-1234-1234-123456789012' -Location 'eastus'

.NOTES
    Author: Jason Rinehart aka Technical Anxiety
    Blog: https://technicalanxiety.com
    Last Updated: 2025-01-15
    
    Original Contributors: cherbison, dnite
    
    Prerequisites:
    - Azure Automation Account with Run As Account configured
    - Service Principal must have Contributor or VM Contributor role
    - Required PowerShell modules: Az.Accounts, Az.Compute, Az.OperationalInsights
    
    Automatic Handling:
    - AKS nodes are automatically skipped (managed by AKS)
    - VMs without monitoring agents are skipped
    - VMs already connected to target workspace are skipped
    - Only removes agents connected to different workspaces
    
    Typical Workflow:
    1. Run this script to remove agents from old workspace
    2. Run ta-install-monitoring-runbook.ps1 to install agents for new workspace
    
    Impact: Enables workspace migration and consolidation by removing agents
    connected to incorrect workspaces. Essential for workspace cleanup and migration.

.VERSION
    2.0.0 - Enhanced documentation

.CHANGELOG
    2.0.0 - 2025-01-15 - Enhanced documentation and code cleanup
    1.0.0 - 2020-01-16 - Initial version
#>
##gather parameters
param (
    # [Parameter(Mandatory=$True)]
    # [String]$WorkspaceName,
    [Parameter(Mandatory = $True)]
    [String]$WorkspaceCustomerId,
    # [Parameter(Mandatory=$True)]
    # [String]$WorkspaceSharedKey,
    [Parameter(Mandatory = $True)]
    [String]$Location
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
#$VMs = @()
#$ExtensionName = 'MonitoringAgent'
# $Workspace = Get-AzOperationalInsightsWorkspace | Where-Object {$_.Name -eq $WorkspaceName}
# $WorkspaceSharedKeys = Get-AzOperationalInsightsWorkspaceSharedKey -Name $WorkspaceName -ResourceGroupName $Workspace.ResourceGroupName -WarningAction SilentlyContinue -ErrorAction Stop
##do not continue if no workspace found
# if (!($Workspace)) {
# Write-Error "Workspace $WorkspaceName not found."
# }
##do not continue if no valid workspace key
# if (!($WorkspaceSharedKeys)) {
# Write-Error "Workspace shared keys for $Workspace not found."
# }
##get a list of all virtual machines
Write-Output "Getting a list of all virtual machines."
$Resources = Get-AzVM -Location $Location -Status
##do not continue if no virtual machines found
if (!$Resources) {
    Write-Error "There was a problem retrieving machines for [$($Location)]. Exception: $($Error[0])"
    return
}
##check for AKS nodes and VMs with an existing Monitoring Agent installed
ForEach ($Resource in $Resources) {
    if ($Resource.Name.StartsWith("aks-")) {
        Write-Output "[$($Resource.Name)] is an AKS node. Skipping..."
    }
    else {
        switch ($Resource.StorageProfile.OsDisk.OsType) {
            'Linux' {
                $ExtensionType = 'OmsAgentForLinux'
            }
            'Windows' {
                $ExtensionType = 'MicrosoftMonitoringAgent'
            }
        }
        $VMEx = Get-AzVMExtension `
            -ResourceGroupName $Resource.ResourceGroupName `
            -VMName $Resource.Name `
            -Name $ExtensionType `
            -ErrorAction "SilentlyContinue"
        if ($VMEx) {
            $workspaceId = $VMEx.PublicSettings | ConvertFrom-Json | Select-Object workspaceId -ExpandProperty workspaceId
            if ($workspaceId -ne $WorkspaceCustomerId -and !([string]::IsNullOrWhiteSpace($workspaceId))) {
                Write-Output "[$($Resource.Name)] Connected to a different workspace - [$($workspaceId)]"
                Write-Output "[$($Resource.Name)] Removing from workspace [$($workspaceId)]"
                Remove-AzVMExtension `
                    -ResourceGroupName $Resource.ResourceGroupName `
                    -VMName $Resource.Name `
                    -Name $VMEx.Name `
                    -Force `
                    -ErrorAction "SilentlyContinue" | Out-Null
                if ($?) {
                    Write-Output "[$($Resource.Name)] Successfully removed from workspace [$($workspaceId)]"
                }
                else {
                    Write-Error "[$($Resource.Name)] Unable to remove from workspace [$($workspaceId)]. Check the VM logs."
                }
            }
            elseif ($workspaceId -eq $WorkspaceCustomerId) {
                Write-Output "[$($Resource.Name)] Already connected to workspace [$($workspaceId)] Skipping..."
            }
        }
        else { Write-Output "[$($Resource.Name)] Does not have the monitoring agent extension installed" }
    }
    Clear-Variable -Name 'VMEx'
    Clear-Variable -Name 'workspaceId'
}