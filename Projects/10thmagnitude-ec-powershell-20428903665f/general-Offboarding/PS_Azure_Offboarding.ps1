############# FUNCTIONS #############
############# FUNCTIONS #############
############# FUNCTIONS #############

#This functions deletes AD groups based on tenants names also if the DeleteAlso variable says AlsoReader, it deletes the Reader group as well
function PerformAzureADGroupsDeletion{Param($TenantID,$DeleteAlso)
Remove-AzureAdGroup -ObjectId (Get-AzureADGroup -SearchString ("AZR-"+$TenantID + "-Owner")).ObjectId
Remove-AzureAdGroup -ObjectId (Get-AzureADGroup -SearchString ("AZR-"+$TenantID + "-Contributor")).ObjectId
Remove-AzureAdGroup -ObjectId (Get-AzureADGroup -SearchString ("AZR-"+$TenantID + "-Reader")).ObjectId

switch ($DeleteAlso){
AlsoReader{
$bu, $bapp, $tennum, $environment = $TenantID.Split('-')
Remove-AzureAdGroup -ObjectId (Get-AzureADGroup -SearchString ("AZR-"+$bu+"-"+ $bapp+"-"+$tennum+"-Reader")).ObjectId
write-host "The reader account for this tenant has been slained.."

}

withoutReader{ write-host "The reader account for this tenant has been spared.."}
}
}

#This function checks if a given TenantID represents all the possible environments for an application from a Business Unit, 
#if it found another environment possible for a Tenant it returns the string "False" since it is not the only Environment for a given Tenant
Function CheckIfThisISTheOnlyEnvType {Param ($SubName,$TenantID,$Subs)
#Sets the return value to True expecting not finding any other environment
$IsTheOnlyEnv = "True"

#Disarm the Tenant ID and create the possible tenants that could exist
$bu, $bapp, $tennum, $environment = $TenantID.Split('-')

$possibleTennatntP = $bu+"-"+ $bapp+"-"+$tennum+"-P"
$possibleTennatntD = $bu+"-"+ $bapp+"-"+$tennum+"-D"
$possibleTennatntS = $bu+"-"+ $bapp+"-"+$tennum+"-S"
$possibleTennatntQ = $bu+"-"+ $bapp+"-"+$tennum+"-Q"

#Create an array with all possible Tenants
$Tenants = $possibleTennatntP,$possibleTennatntD,$possibleTennatntS,$possibleTennatntQ
#Remove the original tenant so it doesn't get checked twice
$Tenants= $Tenants -replace $TenantId,"removeOriginal"

#Disarm the Subscription name and create its counterpart
$SubBU,$SubEnvironment = $SubName.Split('-')
if($SubEnvironment -eq "NONP"){
$Counterpart = $SubBU+"-PROD"
}
else{
$Counterpart = $SubBU+"-NONP"
}

#Load both the original sub and its counterpart to an array
$SubcscriptionEnvironemnts = $SubName,$Counterpart
#Scrol through the subscriptions
foreach($oneSub in $SubcscriptionEnvironemnts){
#Select the current sub being scrolled
Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $oneSub}).Id

#Scroll through all possible tenants except the original for other application environments
foreach ($oneTenant in $Tenants){
                    #Search for Resource groups tagged with the currently scrolled tenant ID
                    $Resourcegroups = Find-AzureRmResourceGroup -Tag @{ TenantId="$oneTenant" }
                    #If at elast 1 is found change the flag of "Only Environment" to False
                    if ($Resourcegroups.Count -gt 0){ $IsTheOnlyEnv = "False"}
                    }
}
#Return to the original sub not sure why but I recall I had to do this just in case for something
Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $SubName}).Id
#Return the result of the probe perform for this TenantId
Return $IsTheOnlyEnv
}



#This function Deletes an entire Tenant
function PerformTenantDeletion {Param ($SubName,$TenantID,$Subs)
#Disarm the Tenant into all its possible variants
$bu, $bapp, $tennum, $environment = $TenantID.Split('-')
$possibleTennatntP = $bu+"-"+ $bapp+"-"+$tennum+"-P"
$possibleTennatntD = $bu+"-"+ $bapp+"-"+$tennum+"-D"
$possibleTennatntS = $bu+"-"+ $bapp+"-"+$tennum+"-S"
$possibleTennatntQ = $bu+"-"+ $bapp+"-"+$tennum+"-Q"

#Save all variants including the original into an array
$Tenants = $possibleTennatntP,$possibleTennatntD,$possibleTennatntS,$possibleTennatntQ
#Disarm the Subscription name and create its counterpart
$SubBU,$SubEnvironment = $SubName.Split('-')

if($SubEnvironment -eq "NONP"){
$Counterpart = $SubBU+"-PROD"
}
else{
$Counterpart = $SubBU+"-NONP"
}
#Load both the original sub and its counterpart to an array
$SubcscriptionEnvironemnts = $SubName,$Counterpart
#Scroll through both Subs
foreach($oneSub in $SubcscriptionEnvironemnts){
#Select the currently scrolled sub
Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $oneSub}).Id
#Scroll through all the tenants including the original one
foreach ($oneTenant in $Tenants){
                    #Look for resource groups using the current Tenant
                    $Resourcegroups = Find-AzureRmResourceGroup -Tag @{ TenantId="$oneTenant" }
                    #For each name of resource groups found perform a deletion
                    foreach ($RGtodelete in ($Resourcegroups.Name)){
                    Remove-AzureRmResourceGroup -Name $RGtodelete
                    }
                    #After all resource groups were deleted perform a deletion of this particular tenant's AD groups and try to delete the Reader account
                    PerformAzureADGroupsDeletion $oneTenant "AlsoReader"
                    }
}
#Remove PROD and NONP Applications
Remove-AzureADApplication -ObjectId (Get-AzureADServicePrincipal -SearchString ("SPN-"+$bu+"-"+$bapp+"-"+$Tennum+"-PROD")).AppId
Remove-AzureADApplication -ObjectId (Get-AzureADServicePrincipal -SearchString ("SPN-"+$bu+"-"+$bapp+"-"+$Tennum+"-NONP")).AppId
#Delete PROD and NONP SPNs
Remove-AzureADServicePrincipal -ObjectId (Get-AzureADServicePrincipal -SearchString ("SPN-"+$bu+"-"+$bapp+"-"+$Tennum+"-PROD")).ObjectId
Remove-AzureADServicePrincipal -ObjectId (Get-AzureADServicePrincipal -SearchString ("SPN-"+$bu+"-"+$bapp+"-"+$Tennum+"-NONP")).ObjectId
}

#This functions deletes a particular environment of a tenant
function PerformEnvironmentDeletion {Param ($TenantID)
                    #Looks for the resource groups using these Tenant tag and deletes them
                    $Resourcegroups = Find-AzureRmResourceGroup -Tag @{ TenantId="$TenantID" }
                    foreach ($RGtodelete in ($Resourcegroups.Name)){
                    Remove-AzureRmResourceGroup -Name $RGtodelete
                    }
                    #Show message about what it deleted
                    Write-Host "Deleted the following Resource Groups from this environment"
                    foreach ($resname in ($($Resourcegroups | select name).Name)){
                    Write-Host $resname
                    }
                    #Perform azure AD group deletion of this particular Tenant WITHOUT the reader account becuase other tenants are using it
                    PerformAzureADGroupsDeletion $TenantID "withoutReader"
                    
}



############################ MAIN CODE #################################
############################ MAIN CODE #################################
############################ MAIN CODE #################################


#Login and subscription select#
Login-AzureRmAccount
$Subs = Get-AzureRmSubscription

#Show message in regards to what subscription to select, use regular expression to show only the subs that fit the naming XXX-YYYY
$SubsNames = $Subs.Name | Where-Object {$_ -match '^\S{3}' + "-" + '\S{4}$'}
Write-Host "Please select one of the subscriptions below to be used as the target for this resource group:" 
write-host ""

$SubsNames|format-table 
Write-Host ""
$SubName = read-host "Type down or paste your subscription selection"

#Select Subscription

$sub = Select-AzureRmSubscription -SubscriptionId ($Subs |Where-Object {$_.Name -eq $SubName}).Id


Write-host "Select the type of offboarding to complete
1.- Single Instance offboarding

2.- Single Environment offboarding

3.- Full Tenant offboarding"
$option = Read-Host "Enter choice and press enter"
cls
Write-Host ""
Write-Host ""
$TenantID = Read-Host "Enter the tenant ID"
switch($option){
        1{#Single instance offboarding
            $Resourcegroups = Find-AzureRmResourceGroup -Tag @{ TenantId="$tenant" }
                    if ($Resourcegroups.Count -gt 1){
                        write-host "Found the following resource groups using this tenant"
                        foreach ($resname in ($($Resourcegroups | select name).Name)){
                        Write-Host $resname
                    }
                        $RGtodelete = read-Host "Type which instance to delete and press enter"
                        Remove-AzureRmResourceGroup -Name $RGtodelete
                    }
                    else{
                        $aboutToDeleteTenant = CheckIfThisISTheOnlyEnvType $SubName $TenantID $Subs
                            if ($aboutToDeleteTenant -eq "True"){
                                Write-Host "This is the only Instance of this environment type, and also is the only environment for this tenant, you will be deleting this tenant entirely" -BackgroundColor Red
                                Read-Host "Press Enter to continue"
                                PerformTenantDeletion $SubName $TenantID $Subs
                                
                            }
                            else{
                                Write-Host "This is the only Instance of this environment type, by continuing to delete this Intance you will be removing this type of environment for this tenant" -BackgroundColor Red
                                Read-Host "Press Enter to continue"
                                PerformEnvironmentDeletion  $TenantID


                            }
                    }
        
        }

        2{#Environment offboarding
        Write-Host "By continuing to you will be removing this type of environment for this Tenant" -BackgroundColor Red
        Read-Host "Press Enter to continue"
        PerformEnvironmentDeletion  $TenantID
        }
        3{#Entire Tenant Offboarding
        Write-Host "By continuing to delete this Tenant, all of the environment this tenant has will be deleted" -BackgroundColor Red
        Read-Host "Press Enter to continue"
        PerformTenantDeletion $SubName $TenantID $Subs
        }
}








