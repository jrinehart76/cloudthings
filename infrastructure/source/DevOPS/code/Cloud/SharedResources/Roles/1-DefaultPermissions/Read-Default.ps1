function Assign-RoleDefinition {
	param (
	  $ResourceType,
	  $ResourceGroupName,
	  $RoleDefinitionName,
	  $PrincipalId
	)

	$resources = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	foreach($r in $resources) {
	Write-Output "Creating assignment for $($PrincipalId) in resource group $($ResourceGroupName) for $($RoleDefinitionName)..."
	try {
			New-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
			-ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
			write-Output "Complete."
	    } catch {
			Write-Output $Error[0]
	    }
	}
}


function Get-RoleDefinition {
	param (
	  $ResourceType,
	  $ResourceGroupName,
	  $RoleDefinitionName,
	  $PrincipalId
	)

	$resources = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	foreach($r in $resources) {
	try {
		Get-AzureRmRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	    -ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	    } catch {
		Write-Output $Error[0]
	    }
	}
}

<#
devops poc sub id
00000000-0000-0000-0000-000000000000

test-rbac-01 group id
00000000-0000-0000-0000-000000000000
#>

[Array]$ResourceGroup = Get-AzureRmResourceGroup | Where ResourceGroupName -match "^perm*" | foreach ResourceGroupName
$subId = '00000000-0000-0000-0000-000000000000'
[array]$PrincipalId = "00000000-0000-0000-0000-000000000000"

# set subscription to datalake
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){
    foreach($r in $ResourceGroup){

        # API Management
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service reader"
        }else{Write-Output "Permissions Already Exists"}

        # App Service Environment
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

        # Storage Permissions
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

	    # Application Gateway
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

	    # Cosmos DB
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

		# HDI
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

	    # MySQL
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

	    # Redis
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}

	    # Virtual Machines
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "reader"
        }else{Write-Output "Permissions Already Exists"}
    }
}