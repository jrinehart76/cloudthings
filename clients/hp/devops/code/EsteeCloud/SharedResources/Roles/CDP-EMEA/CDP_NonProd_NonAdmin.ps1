$subId = "61dbdf66-d93a-4580-862a-1c3cf9350703"
[array]$PrincipalId = "2a6f0ea1-bc04-4632-954e-3c0ed9c70863", "928c1b6d-0667-44e5-bdb0-ef16258bfcc0", "b2a87c20-6952-4f6b-87d9-cf94400ae363", "f0154f8d-0c19-45c3-bba1-8d7adbb6397e"

# set subscription to elc-ap-nonprod-v2
Select-AzureRmSubscription -Subscription $subId

foreach($p in $PrincipalId){

# Dev 
New-AzureRmRoleAssignment -ObjectId $p -ResourceGroupName "RG-EU-UKSouth-DEV-CDP" `
-RoleDefinitionName "Reader"

}