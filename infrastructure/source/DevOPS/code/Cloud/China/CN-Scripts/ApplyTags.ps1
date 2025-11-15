#############################################################################################
# This script will apply tags to the resource group then apply to all underlying resources. #
# It will NOT preserve existing tags & tag values.                                          #
#############################################################################################
param (
    [parameter(Mandatory=$true)][string]$ApplicationName,
    [parameter(Mandatory=$true)][string]$ApplicationOwner,
    [parameter(Mandatory=$true)][string]$BusinessOwner,
    [parameter(Mandatory=$true)][string]$CostCenter,
    [parameter(Mandatory=$true)][ValidateSet("Dev", "QA", "UAT", "POC", "Prod", "NonProd","Stage")][string]$Environment,
    [parameter(Mandatory=$true)][ValidateSet("FY19", "FY20")][string]$FiscalYear,
    [parameter(Mandatory=$true)][ValidateSet("EastUS", "WestUS", "EastUS2", "WestUS2","UKSouth", "CentralUS", "SoutheastAsia", "EastAsia", "ChinaEast2")][string]$Location,
    [parameter(Mandatory=$true)][string]$SupportContact,
    [parameter(Mandatory=$true)][string]$ProjectID,
    [parameter(Mandatory=$true)][ValidateSet("AM", "AP", "SR", "EU", "CN")][string]$Region,
    [parameter(Mandatory=$true)][array]$ResourceGroup,
	[parameter(Mandatory=$true)][string]$InstallDate
)

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

$ModifiedDate = get-date -UFormat "%Y.%m.%d"


#$rg = Get-AzureRMResourceGroup -Name $ResourceGroup


foreach($r in $ResourceGroup){
# Tag Resource Group
$rg = Get-AzureRMResourceGroup -Name $r
Set-AzureRMResourceGroup -Name $rg.ResourceGroupName -Tag @{ ApplicationName=$ApplicationName; ApplicationOwner=$ApplicationOwner; BusinessOwner=$BusinessOwner; CostCenter=$CostCenter; Environment=$Environment; FiscalYear=$FiscalYear; InstallDate=$InstallDate; Location=$Location; SupportContact=$SupportContact; ModifiedDate=$ModifiedDate; ProjectID=$ProjectID; Region=$Region; }
}


foreach($r in $ResourceGroup){
$taggedRG = Get-AzureRMResourceGroup -ResourceGroupName $r
# Pass resource group tags to resources
Get-AzureRMResource -ResourceGroupName $taggedRG.ResourceGroupName | ForEach-Object {Set-AzureRMResource -ResourceId $_.ResourceId -Tag $taggedRG.Tags -Force -ErrorAction SilentlyContinue }
}