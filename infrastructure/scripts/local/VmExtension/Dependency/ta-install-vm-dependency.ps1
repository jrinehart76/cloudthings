
# Install-VMDependencyAgent -ResourceGroupName 'rg-int'
param (
    $ResourceGroupName,
    $Throttle = 5
)

$Jobs = @()
$Machines = Get-AzVM -ResourceGroupName $ResourceGroupName -Status

ForEach ($Machine in $Machines) {
    <# 
        https://docs.microsoft.com/en-us/azure/azure-monitor/platform/agents-overview
        The agents can be installed side by side as Azure extensions, however on Linux, 
        the Log Analytics agent must be installed first or else installation will fail.
    #>
    if ($Machine.PowerState -eq 'VM running') {
        if ($Machine.Extensions.Id -imatch 'MonitoringAgent') {
            if (!($Machine.Extensions.Id -imatch 'DependencyAgent')) {
                Switch ($Machine.StorageProfile.OsDisk.OsType) {
                    'Windows' {
                        $ExtensionType = 'DependencyAgentWindows'
                    }
                    'Linux' {
                        $ExtensionType = 'DependencyAgentLinux'
                    }
                }

                $RunningJobs = $Jobs | Where-Object {$_.State -eq 'Running'}

                if ($RunningJobs.Count -ge $Throttle) {
                    Write-Output "Max job queue of ${Throttle} reached. Please wait..."
                    # block until any running job finishes
                    $RunningJobs | Wait-Job -Any | Out-Null
                }

                Write-Output "[$($machine.Name)] ${ExtensionType} is not installed. Starting job..."
                $Jobs += Set-AzVMExtension -AsJob `
                    -ResourceGroupName $Machine.ResourceGroupName `
                    -VMName $Machine.Name `
                    -Location $Machine.Location `
                    -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' `
                    -ExtensionType $ExtensionType `
                    -Name 'DependencyAgent' `
                    -TypeHandlerVersion '9.1'
            } else {
                Write-Output "[$($Machine.Name)] Dependency agent already installed."
            }
        } else {
            Write-Output "[$($Machine.Name)] Please install the OMS agent on prior to installing the dependency agent."
        }
    } else {
        Write-Output "[$($Machine.Name)] VM is not powered on."
    }
}

if ($Jobs.State -eq 'Running') {
    Write-Output "Waiting for remaining jobs to finish..."
    $Jobs | Wait-Job | Out-Null
}

$Jobs