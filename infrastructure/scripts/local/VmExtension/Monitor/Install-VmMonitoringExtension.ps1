
# Install-VmMonitoringExtension -WorkspaceName 'prd-oms-rm' -Location 'eastus2'
param (
    [Parameter(Mandatory=$false)]
    [String]$WorkspaceCustomerId = '00000000-0000-0000-0000-workspace002',

    [Parameter(Mandatory=$false)]
    [String]$WorkspaceSharedKey = 'SH6YmIAtKhZwdKLWjzBPTLFyTc68N7RNYXTmNDTYylZrsmfS1kz2V6xfRnDhQf38wE7/sOjIWrPK7jtv/uLdtw==',

    [Parameter(Mandatory=$false)]
    [String]$Location = 'eastus'
)

#declare global variables
$ExtensionName = 'MonitoringAgent'

#assign protected and public settings for use in enabling the extension, this is where the LA workspace is defined
$PublicSettings = @{
    workspaceId = $WorkspaceCustomerId
}
$ProtectedSettings = @{
    workspaceKey = $WorkspaceSharedKey
}

#get a list of all VMs
Write-Output "Getting a list of all virtual machines."
$Resources = Get-AzVM -Location $Location -Status

# If there are no VMs, do not continue
if (!$Resources) {
    Write-Error "There was a problem retrieving machines for [$($Location)]. Exception: $($Error[0])"
    return
}

ForEach ($Resource in $Resources) {
    if ($Resource.Name.StartsWith("aks-")) {
        Write-Output "[$($Resource.Name)] is an AKS node. Skipping..."
    }
    else {
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
}