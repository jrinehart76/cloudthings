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