param (
	[string]
	[parameter(Mandatory=$true)]
	$Location,
	[string]
	[parameter(Mandatory=$true)]
	$Region,
	[string]
	[parameter(Mandatory=$true)]
	$Environment
	[string]
	[parameter(Mandatory=$true)]
	$LogicAppSPNAppID
)

function Assign-RoleDefinition {
	param (
	  $ResourceType,
	  $ResourceGroupName,
	  $RoleDefinitionName,
	  $PrincipalId
	)

	$resources = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	    foreach($r in $resources) {
	    Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	    try {
	        New-AzRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	        -ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	        write-Output "Complete."
	    } catch {
	    Write-Output $Error[0]
	    }

	    }
    
}



$PrincipalID = @()
$PrincipalID += (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalAdmin')[0].Id


# Keyvault Access Policies

$allKeyvaults = "AKV-AM-EUS-Dev-DLG","AKV-AM-EUS-Dev-DLG-DTC","AKV-AM-EUS-Dev-DLG-Fin","AKV-AM-EUS-Dev-DLG-HR","AKV-AM-EUS-Dev-DLG-Mkt","AKV-AM-EUS-Dev-DLG-SC"
$keyvaultRG = "RG-AM-EastUS-Dev-DLG-OtherPAAS"

foreach($k in $allKeyvaults){
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString '10thMagnitudeDevOps')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString '10thMagnitudeSupport')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
Set-AzKeyVaultAccessPolicy -VaultName $k -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalAdmin')[0].Id -PermissionsToSecrets get,list,set,delete,recover,backup,restore
}

Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_All')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_Fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_DTC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_HR')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_SC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_CsMkt')[0].Id -PermissionsToSecrets get,list

Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG-Fin" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_Fin')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG-DTC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_DTC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG-Mkt" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_CsMkt')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG-SC" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_SC')[0].Id -PermissionsToSecrets get,list
Set-AzKeyVaultAccessPolicy -VaultName "AKV-AM-EUS-Dev-DLG-HR" -ResourceGroupName $keyvaultRG -ObjectId (Get-AzADGroup -SearchString 'U-CUST-A-EDLGlobalDev_HR')[0].Id -PermissionsToSecrets get,list



foreach($p in $PrincipalId){


# ASE 
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Web Plan Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Website Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Logic App Contributor"



# SQL 
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-ResourceType "Microsoft.Sql/servers" -RoleDefinitionName "SQL Server Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-RoleDefinitionName "Reader"

Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


# Storage
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-DataStorage" `
-ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"


# DataFactory
Assign-RoleDefinition -PrincipalId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"

New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-ADFS" `
-RoleDefinitionName "Contributor"


# Servers
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Servers" `
-RoleDefinitionName "Reader"


# KeyVaults (OtherPaaS) 
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-OtherPAAS" `
-RoleDefinitionName "Reader"


# DataBrick
New-AzRoleAssignment -ObjectId $p -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-DataBrick" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -PrincipalId "b1d6dada-f046-4e18-b489-94c1016bb9b3" -ResourceGroupName "RG-AM-EastUS-NonProd-DLG-DataBrick" `
-ResourceType "Microsoft.Databricks/workspaces" -RoleDefinitionName "Contributor" -ResourceName 'databrick-am-eastus-nonprod-dlg'

}


# Logic App PermissionsToSecrets
#$LogicAppSPNAppID = "32508991-e4a9-4788-b261-6d67e649cdd2"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-ASE" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Prepared" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-Servers" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-DataStorage" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-$($Environment)-DLG-OtherPaaS" `
-RoleDefinitionName "Reader"


New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-NonProd-DLG-DataBrick" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-Dev-DLG-ADFS" `
-RoleDefinitionName "Reader"

New-AzRoleAssignment -ApplicationId $LogicAppSPNAppID -ResourceGroupName "RG-$($Region)-$($Location)-Dev-DLG-ADFS" `
-RoleDefinitionName "Data Factory Contributor"
