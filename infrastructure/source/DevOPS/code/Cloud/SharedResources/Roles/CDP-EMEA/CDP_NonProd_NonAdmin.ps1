$subId = "00000000-0000-0000-0000-000000000000"
[array]$PrincipalId = "00000000-0000-0000-0000-000000000000", "00000000-0000-0000-0000-000000000000", "00000000-0000-0000-0000-000000000000", "00000000-0000-0000-0000-000000000000"

# set subscription to CUST-A-ap-nonprod-v2
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){

# Dev 
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "rg-region3-UKSouth-DEV-CDP" `
-RoleDefinitionName "Reader"

}