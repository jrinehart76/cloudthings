param (
    [string]
    [parameter(Mandatory=$true)]
    $ApplicationId,
    [string]
    [parameter(Mandatory=$true)]
    $CPUThreshold,
    [string]
    [parameter(Mandatory=$true)]
    $MemoryInGB,
    [string]
    [parameter(Mandatory=$true)]
    $ScriptPath,
    [string]
    [parameter(Mandatory=$true)]
    $VmName,
    [string]
    [parameter(Mandatory=$true)]
    $ResourceGroup
)

  (cat $ScriptPath) -replace "#{AppId}#",$ApplicationId `
					-replace "#{AppCpuCount}#",$CPUThreshold `
					-replace "#{AppMemoryInGB}#",$MemoryInGB `
					> ./quotas.sh
  Invoke-AzureRmVMRunCommand -ResourceGroupName $ResourceGroup -VMName $VmName -CommandId RunShellScript -ScriptPath ./quotas.sh
