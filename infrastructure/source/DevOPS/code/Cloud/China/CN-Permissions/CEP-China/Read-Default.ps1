[Array]$ResourceGroup = Get-AzResourceGroup | Where {($_.ResourceGroupName -like "*CEP*") -and  ($_.ResourceGroupName -notmatch "^MC*")} | foreach ResourceGroupName
$subId = '93be8cec-1449-48fd-8b0d-64a650f2f826'
[array]$PrincipalId = "da79c72a-9d43-4227-8c98-d5075f8fa4ef"

# set subscription to datalake
Select-AzSubscription -Subscription $subId

foreach($p in $PrincipalId){
	foreach($r in $ResourceGroup){
		# Dev 
		New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName $r `
		-RoleDefinitionName "Reader"
	}
}