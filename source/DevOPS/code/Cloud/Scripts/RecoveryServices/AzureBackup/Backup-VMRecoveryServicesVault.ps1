Param(

  [Parameter(Mandatory=$True)]
  [string]$resourceGroupName,
  [Parameter(Mandatory=$True)]
  [string]$vmName,
  [Parameter(Mandatory=$True)]
  [string]$vaultName,
  [Parameter(Mandatory=$True)]
  [string]$policyName
)

Get-AzureRmRecoveryServicesVault -Name $vaultName | Set-AzureRmRecoveryServicesVaultContext
$policy = Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name $policyName
Enable-AzureRmRecoveryServicesBackupProtection -ResourceGroupName $resourceGroupName -Name $vmName -Policy $policy
