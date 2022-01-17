<#
    .DESCRIPTION
        Installs dependency extension for Windows and Linux VMs in subscription or optionally by resource group

    .PREREQUISITES
        Must have existing AzureRunAsAccount

    .DEPENDENCIES
        Az.Accounts
        Az.Compute

    .TODO

    .NOTES
        
    .CHANGELOG

    .VERSION
        1.0.0
#>

param (
    [Parameter(Mandatory=$False)]
    [String]$ResourceGroupName = 'rg-int'
)

$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
} Catch {
    if (!$Connection)
    {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

if ($ResourceGroupName) {
    $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
} else {
    $VMs = Get-AzVM
}

if (!($VMs)) {
    Write-Error "No VMs found in subscription or resource group."
    return
}

ForEach ($VM in $VMs) {
    <# 
        https://docs.microsoft.com/en-us/azure/azure-monitor/platform/agents-overview
        The agents can be installed side by side as Azure extensions, however on Linux, 
        the Log Analytics agent must be installed first or else installation will fail.
    #>
    if ($VM.PowerState -eq 'VM running') {
        if ($VM.Extensions.Id -imatch 'MonitoringAgent') {
            if (!($VM.Extensions.Id -imatch 'DependencyAgent')) {

                Switch ($VM.StorageProfile.OsDisk.OsType) {
                    'Windows' {
                        $ExtensionType = 'DependencyAgentWindows'
                    }
                    'Linux' {
                        $ExtensionType = 'DependencyAgentLinux'
                    }
                }

                Set-AzVMExtension `
                    -ResourceGroupName $VM.ResourceGroupName `
                    -VMName $VM.Name `
                    -Location $VM.Location `
                    -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' `
                    -ExtensionType $ExtensionType `
                    -Name 'DependencyAgent' `
                    -TypeHandlerVersion '9.1'
            } else {
                Write-Output "[$($VM.Name)] Dependency agent already installed."
            }
        } else {
            Write-Output "[$($VM.Name)] Please install the OMS agent on prior to installing the dependency agent."
        }
    } else {
        Write-Output "[$($VM.Name)] VM is not powered on."
    }
}