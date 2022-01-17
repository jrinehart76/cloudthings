param 
(
    [string]$ResourceGroupName,
    [string]$AdminADGroup,
	[string]$NonAdminADGroup

)

$PrincipalId = (Get-AzADGroup -SearchString $AdminADGroup)[0].Id

if($NonAdminADGroup -eq 'NA'){
	write-host "no non admin ad group supplied"
}else{
	$NonAdminPrincipalId = (Get-AzADGroup -SearchString $NonAdminADGroup)[0].Id
}

function Assign-RoleDefinition 
{
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
function Get-RoleDefinition 
{
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
foreach($p in $PrincipalId){
    foreach($r in $ResourceGroupName){

        # API Management
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service reader role"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ApiManagement/service" -RoleDefinitionName "API Management Service reader role"
        }else{Write-Output "APIM Permissions Already Exists"}

        # App Service Environment
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Web Plan Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/hostingEnvironments" -RoleDefinitionName "Web Plan Contributor"
        }else{Write-Output "ASE Permissions Already Exists"}

		# App Service Plan
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/serverFarms" -RoleDefinitionName "Website Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Web/serverFarms" -RoleDefinitionName "Website Contributor"
        }else{Write-Output "App Service Plan Permissions Already Exists"}

		# Azure Container Registry
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerRegistry/registries" -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerRegistry/registries" -RoleDefinitionName "Reader"
        }else{Write-Output "ACR Permissions Already Exists"}

        # Storage Permissions
        $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Contributor"
        }else{Write-Output "Storage Permissions Already Exists"}

	    # Application Gateway
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Network/applicationGateways" -RoleDefinitionName "Reader"
        }else{Write-Output "App Gateway Permissions Already Exists"}

	    # Cosmos DB
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "DocumentDB Account Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DocumentDB/databaseAccounts" -RoleDefinitionName "DocumentDB Account Contributor"
        }else{Write-Output "Cosmos DB Permissions Already Exists"}

		# HDI
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.HDInsight/clusters" -RoleDefinitionName "Reader"
        }else{Write-Output "HDI Permissions Already Exists"}

	    # MySQL
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DBforMySQL/servers" -RoleDefinitionName "Reader"
        }else{Write-Output "My SQL Permissions Already Exists"}

	    # Redis
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "Redis Cache Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Cache/Redis" -RoleDefinitionName "Redis Cache Contributor"
        }else{Write-Output "Redis Permissions Already Exists"}

	    # PaaS SQL
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Sql/servers" -RoleDefinitionName "SQL Server Contributor"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Sql/servers" -RoleDefinitionName "SQL Server Contributor"
        }else{Write-Output "SQL Permissions Already Exists"}

	    # Virtual Machines
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Compute/virtualMachines" -RoleDefinitionName "Reader"
        }else{Write-Output "VMs Permissions Already Exists"}

		# AKS Cluster User Role
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerService/managedClusters" -RoleDefinitionName "Azure Kubernetes Service Cluster User Role"
        If($ifExists -eq $Null)
        {
		    Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.ContainerService/managedClusters" -RoleDefinitionName "Azure Kubernetes Service Cluster User Role"
        }else{Write-Output "AKS Permissions Already Exists"}

		# ADFS
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"
        If($ifExists -eq $Null)
        {
			Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.DataFactory/factories" -RoleDefinitionName "Contributor"
        }else{Write-Output "ADFS Permissions Already Exists"}


		# Logic App Contributor
	    $ifExists = Get-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Logic/workflows" -RoleDefinitionName "Logic App Contributor"
        If($ifExists -eq $Null)
        {
			Assign-RoleDefinition -PrincipalId $p -ResourceGroupName $r -ResourceType "Microsoft.Logic/workflows" -RoleDefinitionName "Logic App Contributor"
        }else{Write-Output "Logic App Permissions Already Exists"}

		<#
		# Logic App Contributor - create additional Logic Apps
	    $ifExists = Get-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Logic App Contributor"
        If($ifExists -eq $Null)
        {
            New-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Logic App Contributor"
        }else{Write-Output "Logic App Permissions Already Exists"}
		#>

        # RG Reader
	    $ifExists = Get-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Reader"
        If($ifExists -eq $Null)
        {
            New-AzRoleAssignment -ObjectId $p -ResourceGroupName $r -RoleDefinitionName "Reader"
        }else{Write-Output "RG Reader Permissions Already Exists"}


    }
}

If($NonAdminPrincipalId -ne "NA"){
	foreach($p in $NonAdminPrincipalId){
		foreach($r in $ResourceGroupName){
			New-AzRoleAssignment -ObjectId $p -ResourceGroupName $ResourceGroupName -RoleDefinitionName "Reader"
		}
	}
}else{
	write-host "No Non Admin AD Group Provided"
}