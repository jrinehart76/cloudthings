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


function Get-RoleDefinition {
	param (
	  $ResourceType,
	  $ResourceGroupName,
	  $RoleDefinitionName,
	  $PrincipalId
	)

	$resources = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType

	foreach($r in $resources) {
	try {
		Get-AzRoleAssignment -ObjectId $PrincipalId -ResourceGroupName $ResourceGroupName `
	    -ResourceType $ResourceType -RoleDefinitionName $RoleDefinitionName -ResourceName $r.Name -Verbose
	    } catch {
		Write-Output $Error[0]
	    }
	}
}

<#
CUST-A-CN-NonProd
93be8cec-1449-48fd-8b0d-64a650f2f826

U-CUST-A-CEPChina-Admins-Cloud 
da79c72a-9d43-4227-8c98-d5075f8fa4ef

#>

[Array]$ResourceGroup = Get-AzResourceGroup | Where {($_.ResourceGroupName -like "*CEP*") -and  ($_.ResourceGroupName -notmatch "^MC*")} | foreach ResourceGroupName
$subId = '93be8cec-1449-48fd-8b0d-64a650f2f826'
[array]$PrincipalId = "da79c72a-9d43-4227-8c98-d5075f8fa4ef"

# set subscription to datalake
Select-AzSubscription -Subscription $subId

foreach($p in $PrincipalId){
    foreach($r in $ResourceGroup){

	    # AKS Management
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerService/managedClusters" -RoleDefinitionName "Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerService/managedClusters" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}


        # API Management
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service Contributor"
        }else{Write-Output "Permissions Already Exists"}

        # App Service Environment
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}

	    # Application Gateway
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}

	    # Cosmos DB
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}

		# HDI
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}

	    # MySQL
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}


	    # Redis
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}

		# Storage Permissions
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}


	    # Virtual Machines
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "Contributor"
        }else{Write-Output "Permissions Already Exists"}


	    ### Resource Group Level Permissions

	    # Logic App
	    $ifExists = Get-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Logic App Contributor"
        If($ifExists -eq $Null)
        {
		    New-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Logic App Contributor"
        }else{Write-Output "Permissions Already Exists"}

	    # Web App 
	    $ifExists = Get-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Web Plan Contributor"
        If($ifExists -eq $Null)
        {
		    New-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Web Plan Contributor"
        }else{Write-Output "Permissions Already Exists"}

	    $ifExists = get-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Website Contributor"
        If($ifExists -eq $Null)
        {
		    New-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Website Contributor"
        }else{Write-Output "Permissions Already Exists"}

    }
}