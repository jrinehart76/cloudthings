Param(

  [Parameter(Mandatory=$True)]
  [string]$subName,

  [Parameter(Mandatory=$True)]
  [string]$resourceAbv,

  [Parameter(Mandatory=$True)]
  [string]$region,

  [Parameter(Mandatory=$True)]
  [string]$azureLocation,

  [Parameter(Mandatory=$True)]
  [string]$environment,

  [Parameter(Mandatory=$True)]
  [string]$application,

  [Parameter(Mandatory=$True)]
  [string]$resourceGroup,

  [Parameter(Mandatory=$True)]
  [string]$Iteration,

  [Parameter(Mandatory=$True)]
  [string]$keyVaultName,

  [Parameter(Mandatory=$True)]
  [string]$ResourceType,

  [Parameter(Mandatory=$True)]
  [string]$RoleDefinitionName
)

##################################
$sub = Get-AzureRmSubscription -SubscriptionName $subName
Select-AzureRmSubscription -SubscriptionObject $sub
##################################

$SPNSearchString = "$($resourceAbv)" + '-' + "$($region)" + '-' + "$($azureLocation)" + '-' + "$($environment)" + '-' + "$($application)" + '-' + "$($Iteration)"
$SPN = Get-AzureRmADServicePrincipal -DisplayName $SPNSearchString
New-AzureRmRoleAssignment -ResourceName $keyVaultName -ObjectId $SPN.Id -ResourceGroupName $resourceGroup -ResourceType $resourceType -RoleDefinitionName $RoleDefinitionName

