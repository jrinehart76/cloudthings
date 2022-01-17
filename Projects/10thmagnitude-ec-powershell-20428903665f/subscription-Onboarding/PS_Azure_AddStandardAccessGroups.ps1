
    
# Log in
Login-AzureRmAccount
#Get list of all accessible subscriptions by the user
$Subs = Get-AzureRmSubscription

#Show message in regards to what subscription to select, use regular expression to show only the subs that fit the naming XXX-YYYY
$SubsNames = $Subs.Name | Where-Object {$_ -match '^\S{3}' + "-" + '\S{4}$'}
Write-Host "Please select one of the subscriptions below to be used as the target for this resource group:" 
write-host ""

$SubsNames|format-table
Write-Host ""
$SubName = read-host "Copy and paste the name of the Subscription, for hub zone enter ITS-Shared"

#Select Subscription
$sub = Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $SubName}).Id


function Ensure-AZR-ECL-ALLSUBS-Reader($sub)
{
    $groupname = "AZR-ECL-ALLSUBS-Reader"
    $role = "Reader"

    $group = get-azurermadgroup -searchstring $groupname

    $objectid = $group.id.guid


         
        $result = $null 
        $result = Get-AzureRmRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        if(!$result)
        {
            write-output "   Adding role $role to  $groupname on $($sub.name)" -foregroundcolor cyan
            New-AzureRMRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        } else {
            write-output "   Skipping $($sub.name) as it's already got role $role assigned to $groupname"
        }  
    
}



function Ensure-AZR-ALLSUBS-OWNER($sub)
{
    $groupname = "AZR-ALLSUBS-OWNER"
    $role = "Owner"
  
    $group = $null
    $group = get-azurermadgroup -searchstring $groupname

    $objectid = $group.id.guid
  

        
        $result = Get-AzureRmRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        if(!$result)
        {
            write-output "   Adding role $role to  $groupname on $($sub.name)" -foregroundcolor cyan
            New-AzureRMRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        } else {
            write-output "Skipping $($sub.name) as it's already got role $role assigned to $groupname"
        }
        $result = $null
        
    
    
    
    
}

function Ensure-AzureRole_VirtualMachineContributors($sub)
{
    $groupname = "AzureRole_VirtualMachineContributors"
    $role = "Virtual Machine Contributor"

    $group = get-azurermadgroup -searchstring $groupname

    $objectid = $group.id.guid

    

         
        $result = $null 
        $result = Get-AzureRmRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        if(!$result)
        {
            write-output "   Adding role $role to  $groupname on $($sub.name)" -foregroundcolor cyan
            New-AzureRMRoleAssignment -roleDefinitionName $role  -objectid $objectid -scope "/subscriptions/$($sub.id)"
        } else {
            write-output "   Skipping $($sub.name) as it's already got role $role assigned to $groupname"
        }  
    
}

Ensure-AZR-ALLSUBS-OWNER -sub $sub
Ensure-AZR-ECL-ALLSUBS-Reader -sub $sub
Ensure-AzureRole_VirtualMachineContributors -sub $Sub
    