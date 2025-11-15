<#
    .DESCRIPTION
        Installs monitoring extension to VMs.
        Runs from an Azure Automation account.

    .PREREQUISITES
        Existing AzureRunAsAccount in Automations account
        Recovery Service vault must exist

    .DEPENDENCIES
        Az.Accounts
        Az.Compute
        Az.OperationalInsights

    .TODO
        Check if Recovery Service vault exists

    .NOTES
        AUTHOR: cherbison, jrinehart, dnite
        LASTEDIT: 2020.1.16

    .CHANGELOG

    .VERSION
        1.0.0
#>

##gather parameters
param (
    [Parameter(Mandatory=$True)]
    [String]$WorkspaceName,

    [Parameter(Mandatory=$True)]
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
$VMs = @()
$ExtensionName = 'MonitoringAgent'
$Workspace = Get-AzOperationalInsightsWorkspace | Where-Object {$_.Name -eq $WorkspaceName}
$WorkspaceSharedKeys = Get-AzOperationalInsightsWorkspaceSharedKey -Name $WorkspaceName -ResourceGroupName $Workspace.ResourceGroupName -WarningAction SilentlyContinue -ErrorAction Stop

##do not continue if no workspace found
if (!($Workspace)) {
    Write-Error "Workspace $WorkspaceName not found."
}

##do not continue if no valid workspace key
if (!($WorkspaceSharedKeys)) {
    Write-Error "Workspace shared keys for $Workspace not found."
}

##create hash tables for diagnostic settings
$PublicSettings = @{
    workspaceId = $Workspace.CustomerId
}
$ProtectedSettings = @{
    workspaceKey = $WorkspaceSharedKeys.PrimarySharedKey
}

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
    $VMEx = Get-AzVMExtension `
                -ResourceGroupName $Resource.ResourceGroupName `
                -VMName $Resource.Name `
                -Name $ExtensionName `
                -ErrorAction "SilentlyContinue"
    if ($VMEx) {
        $workspaceId = $VMEx.PublicSettings | ConvertFrom-Json | Select-Object workspaceId -ExpandProperty workspaceId
        if ($workspaceId -ne $Workspace.CustomerId) {
            Write-Output "[$($Resource.Name)] Already connected to workspace [$($workspaceId)]"
            Write-Output "[$($Resource.Name)] Removing from workspace [$($workspaceId)]"
            ##remove the agent if the configured workspace id is not correct
            Remove-AzVMExtension `
                -ResourceGroupName $Resource.ResourceGroupName `
                -VMName $Resource.Name `
                -Name $ExtensionName `
                -Force `
                -ErrorAction "SilentlyContinue" | Out-Null
            if ($?) {
                Write-Output "[$($Resource.Name)] Successfully removed from workspace [$($workspaceId)]"
            } else {
                Write-Error "[$($Resource.Name)] Unable to remove from workspace [$($workspaceId)]. Check the VM logs."
            }
        } elseif ($workspaceId -eq $Workspace.CustomerId) {
            ##skip processing if the configured workspace is correct
            Write-Output "[$($Resource.Name)] is already connected to workspace [$($workspaceId)] Skipping..."
            $skip = 'true'
        }
    }
    ##add any remaining VMs to an array for installation
    if ($skip -ne 'true') { $VMs += $Resource }
}

##install the monitoring agent on all remaining VMs
ForEach ($Resource in $VMs) {
    switch ($Resource.StorageProfile.OsDisk.OsType) {
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
        -ResourceGroupName $Resource.ResourceGroupName `
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