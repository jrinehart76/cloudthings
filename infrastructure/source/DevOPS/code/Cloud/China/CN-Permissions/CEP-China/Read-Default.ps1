[Array]$ResourceGroup = Get-AzResourceGroup | Where {($_.ResourceGroupName -like "*CEP*") -and  ($_.ResourceGroupName -notmatch "^MC*")} | foreach ResourceGroupName
$subId = '00000000-0000-0000-0000-000000000000'
[array]$PrincipalId = "00000000-0000-0000-0000-000000000000"

# set subscription to datalake
Select-AzSubscription -Subscription $subId

foreach($p in $PrincipalId){
	foreach($r in $ResourceGroup){
		# Dev 
		New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName $r `
		-RoleDefinitionName "Reader"
	}
}