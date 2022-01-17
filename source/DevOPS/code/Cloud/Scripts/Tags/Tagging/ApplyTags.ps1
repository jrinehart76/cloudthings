param (
    [parameter(Mandatory=$true)][string]$ApplicationName,
    [parameter(Mandatory=$true)][string]$ApplicationOwner,
    [parameter(Mandatory=$true)][string]$ApplicationDescription,
    [parameter(Mandatory=$true)][ValidateSet("Prod", "NonProd", "Client Patch")][string]$PatchGroup,
    [parameter(Mandatory=$true)][ValidateSet("Yes", "No")][string]$Monitoring,
    [parameter(Mandatory=$true)][string]$NotificationDL,
    [parameter(Mandatory=$true)][string]$BusinessOwner,
    [parameter(Mandatory=$true)][string]$CostCenter,
    [parameter(Mandatory=$true)][ValidateSet("Dev", "QA", "UAT", "POC", "Prod", "NonProd","Stage","DR")][string]$Environment,
    [parameter(Mandatory=$true)][ValidateSet("FY19", "FY20")][string]$FiscalYear,
    [parameter(Mandatory=$true)][ValidateSet("EastUS", "WestUS", "EastUS2", "WestUS2","UKSouth", "CentralUS", "SoutheastAsia", "EastAsia", "ChinaEast2","KoreaCentral")][string]$Location,
    [parameter(Mandatory=$true)][string]$SupportContact,
    [parameter(Mandatory=$true)][string]$ProjectID,
    [parameter(Mandatory=$true)][ValidateSet("AM", "AP", "SR", "EU", "CN")][string]$Region,
    [parameter(Mandatory=$true)][ValidateSet("Yes", "No")][string]$Backup,
    [parameter(Mandatory=$true)][array]$ResourceGroup,
	[parameter(Mandatory=$true)][string]$InstallDate,
    [parameter(Mandatory=$true)][string]$DeployedBy,
    [parameter(Mandatory=$true)][string]$ReviewedBy,
    [parameter(Mandatory=$true)][string]$Justification

)

$ErrorActionPreference = "Stop"

# Validate ApplicationOwner name format is lastname, firstname or NA
if ($ApplicationOwner -cnotmatch '^[A-Z,a-z]{1,99}\, [A-Z,a-z]{1,99}|^NA$') {
    throw "ERROR: $ApplicationOwner is not valid. Please enter a valid name in format of lastname, firstname"
}

# Validate BusinessOwner name format is lastname, firstname or NA
if ($BusinessOwner -cnotmatch '^[A-Z,a-z]{1,99}\, [A-Z,a-z]{1,99}|^NA$') {
    throw "ERROR: $BusinessOwner is not valid. Please enter a valid name in format of lastname, firstname"
}

# Validate install date meets YYYY.MM.DD format
if ($InstallDate -cnotmatch '(^20[0-9]{2}|2[0-9]{3})\.(0[1-9]|1[012])\.([123]0|[012][1-9]|31)$') {
    throw "ERROR: $InstallDate is not valid. Please enter a valid date"
}

#Validate ProjectID meets P####.## format
if ($ProjectID -cnotmatch '^P\d{4}\.\d{2}$') {
    throw "ERROR: $ProjectID is not valid. Enter a Project ID of format P####.##"
}

#Validate Support Contact is an email address or NA
if ($SupportContact -cnotmatch '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}|^NA$') {
    throw "ERROR: $SupportContact is not valid. Please enter a valid email address"
}

#Validate 10MNotificationDL is an email address or NA
if ($NotificationDL -cnotmatch '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}|^NA$') {
    throw "ERROR: $NotificationDL is not valid. Please enter a valid email address"
}

$ModifiedDate = get-date -UFormat "%Y.%m.%d"

try
{
    foreach ($rg in $ResourceGroup)
    {
        Write-Host "`n############################################################"
        Write-Host "Retrieving resource group and resources"
        Write-Host "############################################################`n"

        $rgObject = Get-AzResourceGroup -Name $rg
        $resources = Get-AzResource -ResourceGroupName $rgObject.ResourceGroupName | where {$_.ResourceType -ne "microsoft.insights/metricalerts"}

        Write-Host "`n############################################################"
        Write-Host "Successfully retrieved resource group and resources"
        Write-Host "############################################################`n"

        Write-Host "`n############################################################"
        Write-Host "Tagging Resource Group"
        Write-Host "############################################################`n"
        if (($rgObject.Tags.Keys -contains 'InstallDate') -or ($rgObject.Tags.Keys -contains 'FiscalYear'))
        {
            Set-AzResourceGroup -Name $rgObject.ResourceGroupName -Tag @{ApplicationName=$ApplicationName; ApplicationOwner=$ApplicationOwner; BusinessOwner=$BusinessOwner; CostCenter=$CostCenter; Environment=$Environment; FiscalYear=$rgObject.tags.FiscalYear; InstallDate=$rgObject.tags.InstallDate; Location=$Location; SupportContact=$SupportContact; ModifiedDate=$ModifiedDate; ProjectID=$ProjectID; Region=$Region; Backup=$Backup; PatchGroup=$PatchGroup; Monitoring=$Monitoring; NotificationDL=$NotificationDL; ApplicationDescription=$ApplicationDescription; DeployedBy=$DeployedBy; ReviewedBy=$ReviewedBy; ManagedBy="10th Magnitude"; Justification=$Justification}
        }
        else 
        {
            Set-AzResourceGroup -Name $rgObject.ResourceGroupName -Tag @{ApplicationName=$ApplicationName; ApplicationOwner=$ApplicationOwner; BusinessOwner=$BusinessOwner; CostCenter=$CostCenter; Environment=$Environment; FiscalYear=$FiscalYear; InstallDate=$InstallDate; Location=$Location; SupportContact=$SupportContact; ModifiedDate=$ModifiedDate; ProjectID=$ProjectID; Region=$Region; Backup=$Backup; PatchGroup=$PatchGroup; Monitoring=$Monitoring; NotificationDL=$NotificationDL; ApplicationDescription=$ApplicationDescription; DeployedBy=$DeployedBy; ReviewedBy=$ReviewedBy; ManagedBy="10th Magnitude"; Justification=$Justification}
        }
        
        Write-Host "`n############################################################"
        Write-Host "Resource Group Tagged"
        Write-Host "############################################################`n"

        #Get Date for newly deployed resources to existing RGs
        $InstallDateNewResources = Get-Date -Format "yyyy.MM.dd"

        foreach ($resource in $resources)
        {
            Write-Host "`n############################################################"
            Write-Host "Tagging resource: $($resource.Name)"
            Write-Host "############################################################`n" 

            $TaggedRG = Get-AzResourceGroup -Name $rg

            #resources that only handle 15 tags
            if ($resource.ResourceType -eq 'Microsoft.HDInsight/clusters' -or $resource.ResourceType -eq 'Microsoft.Sql/servers/databases' -or $resource.ResourceType -eq 'Microsoft.PowerBI/workspaceCollections' -or $resource.ResourceType -eq 'Microsoft.Sql/servers' -or $resource.ResourceType -eq 'Microsoft.Web/hostingEnvironments' -or $resource.ResourceType -eq 'Microsoft.Web/serverfarms')  
            {
                $TaggedRG.Tags.Remove('ApplicationDescription')
                $TaggedRG.Tags.Remove('BusinessOwner')
                $TaggedRG.Tags.Remove('SupportContact')
                $TaggedRG.Tags.Remove('ApplicationOwner')
                $TaggedRG.Tags.Remove('Environment')
                $TaggedRG.Tags.Remove('Justification')
            }

            #reset tags if modified below for previous resource
            if (($resource.Tags.Keys -contains "InstallDate") -or ($resource.Tags.Keys -contains "FiscalYear"))
            {
                #if the resource exists, keep the original install dates and fiscal year
                $TaggedRG.Tags.InstallDate = $resource.Tags.InstallDate
                $TaggedRG.Tags.FiscalYear = $resource.Tags.FiscalYear
                Set-AzResource -ResourceId $resource.ResourceId -Tag $TaggedRG.Tags -Force
            }
            else 
            {
                #If new resource group use todays date, if new resource only use todays date
                $TaggedRG.Tags.InstallDate = $InstallDateNewResources    
                Set-AzResource -ResourceId $resource.ResourceId -Tag $TaggedRG.Tags -Force
            }


            Write-Host "`n############################################################"
            Write-Host "Successfully tagged resource: $($resource.Name)"
            Write-Host "############################################################`n"
        }
    }
}
catch
{
    Write-Error "Error in tagging resource $($resource.ResourceName): $_"
}
