Param(
    [parameter(Mandatory=$true)][string]$Location,
	[parameter(Mandatory=$true)][string]$Region
)

$MgmtRG = (Get-AzResourceGroup -Name "RG-$region-$location*-MGMT").ResourceGroupName
$MgmtKeyVault = (Get-AzResource -ResourceType 'Microsoft.KeyVault/vaults' -ResourceGroupName $MgmtRG -Name *).Name

Write-Output "##vso[task.setvariable variable=MgmtKeyvault]$($MgmtKeyVault)"
