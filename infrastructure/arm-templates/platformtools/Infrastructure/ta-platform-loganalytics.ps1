<#
    .DESCRIPTION
        Deploys Azure Monitor Log Workspace

    .PREREQUISITES
        Management Resource Group

    .EXAMPLE
        To input an array, format text like the following:
          "<solutionname>","<solutionname>", ....
        Possible values: AlertManagement, Security, AgentHealthAssessment, ChangeTracking, Updates, AzureAutomation, Containers, ContainerInsights, HDInsightHadoop, HDInsightInteractiveQuery, HDInsightSpark, NetworkMonitoring, ServiceMap, ServiceDesk

    .TODO

    .NOTES

    .CHANGELOG
        
#>

##Parameter input
param (
    [Parameter(Mandatory=$true)]
    [string]$workspaceSubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$workspaceResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$workspaceName,

    [Parameter(Mandatory=$true)]
    [string]$workspaceLocation,

    [Parameter(Mandatory=$true)]
    [string]$workspaceSKU,

    [Parameter(Mandatory=$true)]
    [array]$solutionTypeArray
 )

##Variable definitions **commented out to allow for dynamic input**
<#
$workspaceSubscriptionId = "00000000-0000-0000-0000-000000000000"
$workspaceResourceGroupName  = "PLATFORM-prod-mgmt-01"
$workspaceName     = "la-prod-01"
$workspaceLocation = "East US"
$workspaceSKU      = "PerNode"
$solutionTypeArray= "Security", "ChangeTracking", "Updates", "AzureAutomation", "NetworkMonitoring", "ServiceMap", "ServiceDesk"
#>

##Deploy base workspace for all log data
New-AzResourceGroupDeployment `
  -Name "deploy-log-workspace" `
  -ResourceGroupName $workspaceResourceGroupName `
  -TemplateFile ./templates/platform/workspace.json `
  -workspaceName $workspaceName `
  -workspaceLocation $workspaceLocation `
  -workspaceSKU $workspaceSKU

##Deploy base solutions from marketplace
  New-AzResourceGroupDeployment `
  -Name "deploy-log-workspace-solutions" `
  -ResourceGroupName $workspaceResourceGroupName `
  -TemplateFile ./templates/platform/solution.generic.json `
  -workspaceLocation $workspaceLocation `
  -workspaceResourceGroupName $workspaceResourceGroupName `
  -workspaceSubscriptionId $workspaceSubscriptionId `
  -workspaceName $workspaceName `
  -solutionTypeArray $solutionTypeArray

##Deploy custom backup solution 
  New-AzResourceGroupDeployment `
  -Name "deploy-log-workspace-backup-solution" `
  -ResourceGroupName $workspaceResourceGroupName `
  -TemplateFile ./templates/platform/solution.backup.json `
  -workspaceLocation $workspaceLocation `
  -workspaceName $workspaceName
