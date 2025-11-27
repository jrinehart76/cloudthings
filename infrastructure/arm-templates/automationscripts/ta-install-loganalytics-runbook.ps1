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
        AUTHOR: cherbison, jrinehart
        LASTEDIT: 2019.7.2

    .CHANGELOG

    .VERSION
        1.0.0
#>

##gather parameters
param (
    [Parameter(Mandatory=$True)]
    [String]$WorkspaceName,

    [Parameter(Mandatory=$False)]
    [String]$ResourceGroupName
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
if ($ResourceGroupName) {
    $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
} else {
    $VMs = Get-AzVM
}

##do not continue if no virtual machines found
if (!($VMs)) {
    Write-Error "No VMs found in subscription or resource group."
    return
}

##install the monitoring extension on each running virtual machine
ForEach ($VM in $VMs) {
    Write-Output "[$($VM.Name)] VM is running."

    $Extensions = Get-AzVMExtension -VMName $VM.Name -ResourceGroupName $VM.ResourceGroupName
    
    Switch ($VM.StorageProfile.OsDisk.OsType) {
        'Linux' {
            $ExtensionType = 'OmsAgentForLinux'
            $TypeHandlerVersion = '1.7'
        }
        'Windows' {
            $ExtensionType = 'MicrosoftMonitoringAgent'
            $TypeHandlerVersion = '1.0'
        }
    }
    
    if (!($Extensions.ExtensionType -imatch $ExtensionType)) {

        Write-Output "[$($VM.Name)] ${ExtensionType} is not installed. Installing..."
        Set-AzVMExtension `
            -ResourceGroupName $VM.ResourceGroupName `
            -VMName $VM.Name `
            -Name $ExtensionName `
            -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
            -ExtensionType $ExtensionType `
            -TypeHandlerVersion $TypeHandlerVersion `
            -Location $VM.Location `
            -Settings $PublicSettings `
            -ProtectedSettings $ProtectedSettings
    } else {
        Write-Output "[$($VM.Name)] Extension ${ExtensionType} is already installed. "
    }
}