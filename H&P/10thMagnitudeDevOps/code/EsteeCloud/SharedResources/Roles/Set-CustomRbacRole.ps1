<#
		Set-CustomRbacRole.ps1
#>

param (
	[string]
	[parameter(Mandatory=$true)]
	$RoleName,
	[string]
	[parameter(Mandatory=$true)]
	$JsonDefinitionFile
)

$role = Get-AzureRmRoleDefinition "$($RoleName)"

if(!(Test-Path "$($JsonDefinitionFile)")) {
	Write-Error "JSON definition file at $($JsonDefinitionFile) not found."
	return;
}

if($role -eq $null) {
    Write-Output "$($RoleName) role not found.  Creating..."
    New-AzureRmRoleDefinition -InputFile "$($JsonDefinitionFile)"
    Write-Output "$($RoleName) role created."
} 
else {
    Write-Output "$($RoleName) role found.  Checking for updates..."
    New-AzureRmRoleDefinition -InputFile "$($JsonDefinitionFile)"
    Write-Output "$($RoleName) role updated."
}