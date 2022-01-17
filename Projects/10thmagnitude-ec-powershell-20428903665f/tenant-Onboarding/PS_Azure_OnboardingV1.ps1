##########################################################################################
#    Tenant Onboarding - Pilot Testing                                                   #
#                                                                                        #
#    Gain user input to establish the variable values to build                           #
#    BU/Application team tenant.                                                         #
#    Update Cloud Worksheet with appropriate data for tracking.                          #
##########################################################################################


#######################################################################################
#######################################################################################
############################### FUNCTIONS #############################################
#######################################################################################
#######################################################################################

################## Check if resource exists and create if not ######################################

function Check-If-RG-Exists-And-Create { Param ($businessUnit, $appID, $environment, $i, $tags, $region) 

$script:NumI = "{0:D3}" -f $i
$rgName = "$businessUnit-$appID-$NumI-$environment"
$rg = Get-AzureRmResourceGroup -Name $rgName -ErrorAction SilentlyContinue

        if ($rg.ProvisioningState -eq "Succeeded"){
            #Already exists
            write-host "Found already existing Resource Group $($RG.Resourcegroupname)"
            $NewOrOld = "Old"
            return $rg,$NewOrOld
        }
        else{
            #ResourceGroup doesn't exist    
            $rgName = "$businessUnit-$appID-$NumI-$environment" 
            $rg = New-AzureRmResourceGroup -Name $rgName -Location $region -Tag $tags
            write-host "Resource Group $($RG.Resourcegroupname) did not exists, it has been created"
            $NewOrOld = "New"
            return $rg,$NewOrOld
        }
}

################## Check if Azure AD Group exists and create if not ######################################

function Check-Azure-AD-Group-Exists-And-Create { Param ($AADAppIDReaderGroupName,$AADContributorGroupName,$AADReaderGroupName)

$grpThere = @()
$grps = ( $AADAppIDReaderGroupName, $AADContributorGroupName , $AADReaderGroupName)

    foreach ($grp in $grps){
    $AADGroupName = $grp
    $grpChk= get-azureadgroup -filter "DisplayName eq `'$AADGroupName'"
            if ($grpChk -ne $null){
                $grpThere +=  $grpChk.DisplayName 
            }
            else{
            New-AzureADGroup -DisplayName $AADGroupName -MailEnabled $false -SecurityEnabled $true -MailNickName $AADGroupName
            }
    }
    return $grpThere

}

#############################
 
function createSPN { Param( $tenantID,$SPNPassword,$AADContributorGroup )

    
$biz, $bizapp, $tennum, $envir = $tenantID.Split('-')
switch ($envir) {
            P{ $SPNType = "PROD"
            }
            S{ $SPNType = "PROD"
            }
            default {$SPNType = "NONP"
            }
            }
$script:spnRole= "Contributor" 
$svcName= "SPN"
$displayName= [string]::Format("{0}-{1}-{2}-{3}-{4}",$svcName,$biz,$bizapp,$tennum,$SPNType)
$homePage= "https://" + $displayName
$passwordExpirationDateTime = (Get-Date).AddYears(1)
#[FUTURE]Update DB with the expiration date



#Check if the application already exists

$app= Get-AzureRmADApplication -IdentifierUri $homePage 

if (![String]::IsNullOrEmpty($app) -eq $true)
    {
        $script:applicationId = $app.ApplicationId
       write-host "An Azure AAD Appication with the provided values already exists, skipping the creation of the application..."
    }else

    {
    write-host "aad app doesn't exist...lets make it"

            
                # Create a new AD Application
                   write-host "Creating a new Application in AAD (App URI - $homePage)" 
                        New-AzureRmADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $homePage -Password $SPNPassword -EndDate $passwordExpirationDateTime
                        $script:applicationId = $(get-azurermadapplication -identifierUri $homePage).ApplicationId
                    write-host "Azure AAD Application creation completed successfully (Application Id: $applicationId)" 
                }            



# Check if the principal already exists

$script:spn = Get-AzureRmADServicePrincipal -ServicePrincipalName $applicationId

if (![String]::IsNullOrEmpty($spn) -eq $true)
    
        {
              write-host "An Azure AAD Appication Principal for the application already exists, skipping the creation of the principal..."
   
            }else

                    {
                        # Create new SPN
                           write-host "Creating a new SPN" -Verbose
                                $spn = New-AzureRmADServicePrincipal -ApplicationId $applicationId
                                $script:spnName = $spn.ServicePrincipalNames
                                write-host "SPN creation completed successfully (SPN Name: $spnName)" -Verbose
                                write-host "Waiting for SPN creation to reflect in Directory before Role assignment"
                            Start-Sleep 60
                     }
                    
                    

                    }
# Add the principal role to the Resource Groups (if provided)


   
    


#######################################################################################
#######################################################################################
############################### END OF FUNCTIONS ######################################
#######################################################################################
#######################################################################################






#######################################################################################
#######################################################################################
############################### MAIN CODE #############################################
#######################################################################################
#######################################################################################
$Script:tenantID
$script:SPNPassword
cls
write-host "Select the type of data entry you wish to perform"
write-host ""
write-host "1.- Manual input"
write-host "2.- File based input"
write-host ""
$option = read-host "Enter selection"
switch ($option) {
        1{
            $businessUnit = read-host "Enter Business Unit as XXX"
            $appID = read-host "Enter Application ID as XXX"
            $tenantID = read-host "Enter Tenant ID as XXX-YYY-###-Z" 
            $incrementalNumber = read-host "Enter the amount of environments to build 1..999"
            $environment = read-host "Enter the type of environment D for Dev, P for Prod, T for test or X for POC"
            $businessContact = read-host "Enter the name of the Business Contact for this Tenant"
            $technicalContact =read-host "Enter the name of the Technical Contact for this Tenant"
            $costCenter = read-host "Enter the Cost Center for this Tenant, otherwise leave blank and press Enter"
            $region = read-host "Enter the Region for this Resource Groups, advice is to use East US 2"
            $SPNPassword = read-host "Enter the password for your Service Principal, REMEMBER TO SAVE THIS PASSWORD" 
            cls
                                            #Show confirmation to the user before proceeding
                                write-host "Please confirm the following list of values is correct before proceeding:"
                                write-host ""
                                write-host "businessUnit       $businessUnit"
                                write-host "appID              $appID"
                                write-host "tenantID           $tenantID"
                                write-host "incrementalNumber  $incrementalNumber"
                                write-host "environment        $environment"
                                write-host "businessContact    $businessContact"
                                write-host "technicalContact   $technicalContact"
                                write-host "costCenter         $costCenter"
                                write-host "region             $region"
                                write-host "SPNPassword        $SPNPassword"
                                write-host ""
                                read-host "Press Enter to continue"
        }
        2{
                    Function Get-FileName($initialDirectory){   
                        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null
                        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                        $OpenFileDialog.initialDirectory = $initialDirectory
                        $OpenFileDialog.filter = "All files (*.*)| *.*"
                        $OpenFileDialog.ShowDialog() | Out-Null
                        $OpenFileDialog.filename
                    } 
                            #Using the above defined function, get the CSV file with all the parameters
                            $parameters = Import-Csv (Get-FileName -initialDirectory ".\")
                            #Once the user selects the file, assign the values to the parameters
                            $businessUnit = $parameters.businessUnit
                            $appID = $parameters.appID
                            $tenantID = $parameters.tenantID
                            $incrementalNumber = $parameters.incrementalNumber
                            $environment = $parameters.environment
                            $businessContact = $parameters.businessContact
                            $technicalContact = $parameters.technicalContact
                            $costCenter = $parameters.costCenter
                            $region = $parameters.region
                            $SPNPassword = $parameters.SPNPassword
                                #Show confirmation to the user before proceeding
                                write-host "Please confirm the following list of values is correct before proceeding:"
                                write-host ""
                                write-host "businessUnit       $($parameters.businessUnit)"
                                write-host "appID              $($parameters.appID)"
                                write-host "tenantID           $($parameters.tenantID)"
                                write-host "incrementalNumber  $($parameters.incrementalNumber)"
                                write-host "environment        $($parameters.environment)"
                                write-host "businessContact    $($parameters.businessContact)"
                                write-host "technicalContact   $($parameters.technicalContact)"
                                write-host "costCenter         $($parameters.costCenter)"
                                write-host "region             $($parameters.region)"
                                write-host "SPNPassword        $($parameters.SPNPassword)"
                                write-host ""
                                read-host "Press Enter to continue"
        }
}

 

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

#Connect to azure AD
Connect-AzureAD -TenantId $sub.Tenant.TenantId    #Azure Active Directory Tenant ID (utilizes default tenant id from subscription)

#Generate the name of the AD Group based on Tenant ID 
    $AADContributorGroupName = "AZR-$tenantID-Contributor"
    $AADReaderGroupName = "AZR-$tenantID-Reader"
    $AADAppIDReaderGroupName = "AZR-$BusinessUnit-$AppId-Reader"

#Check if AAD groups exist and create if not 
   $ADgroups = Check-Azure-AD-Group-Exists-And-Create  $AADAppIDReaderGroupName $AADContributorGroupName $AADReaderGroupName

   if($ADgroups -ne ""){
            write-host "Found already existing Azure AD groups"
            write-host "$ADGroups"
   }
   else{
            write-host "No previously existing Azure AD groups were found, created new ones"
            write-host "$AADAppIDReaderGroupName"
            write-host "$AADContributorGroupName"
            write-host "$AADReaderGroupName"
   }
#Pause to allow for group creation to complete before applying in next step
    Start-Sleep -Seconds 10

#Using the confirmed names, get the AAD group object

    $AADContributorGroup = Get-AzureRmADGroup -SearchString $AADContributorGroupName
    $AADReaderGroup = Get-AzureRmADGroup -SearchString $AADReaderGroupName
    $AADAppIDReaderGroup = Get-AzureRmADGroup -SearchString $AADAppIDReaderGroupName

#Add Technical contact as the owner of the Contributors group
    
    Add-AzureADGroupOwner -ObjectId $AADContributorGroup.ID -RefObjectId  (Get-AzureADUser -Filter "userPrincipalName eq '$technicalContact'").ObjectId 
    Add-AzureADGroupOwner -ObjectId $AADReaderGroup.ID -RefObjectId  (Get-AzureADUser -Filter "userPrincipalName eq '$technicalContact'").ObjectId
    Add-AzureADGroupOwner -ObjectId $AADAppIDReaderGroup.ID -RefObjectId  (Get-AzureADUser -Filter "userPrincipalName eq '$technicalContact'").ObjectId 

#Generate Tag set to set on the resource groups
    $tags = @{"BusinessUnit"=$businessUnit; "AppID"=$appID; "TenantID"=$tenantID; "BusinessContact"=$businessContact; "TechnicalContact"=$technicalContact; "CostCenter"=$costCenter; "Environment"=$environment;}

#Break if CostCenter is not defined
    if ($tags.CostCenter -eq ""){Write-Host "This field is required to continue"
    break
    }

#Bring the Azure policy definitions for the policy assigments that will happen on the cycle below
    $StorageAcctReqHTTPSDefinition = Get-AzureRmPolicyDefinition -Name "StorageAcctReqHTTPS"
    $TagDefaultValueDefinition = Get-AzureRmPolicyDefinition -Name "Tag values for inexisting tags"
    $GeoLockdownDefinition = Get-AzureRmPolicyDefinition -Name "Geo-Lockdown"

#If there is no password for an SPN, Do not create a Service Principal 
    if ($SPNPassword -eq ""){
        
            #Do Nothing
                    }else
                          {createSPN  $tenantID $SPNPassword $AADContributorGroup }
                        
# Iterate thru Resource Group Creation based on incremental number of desired groups for this tenant

####################################################### Creation Loop ##############################################################
    for($i = 1; $i -le $incrementalNumber; $i++){

    # Check if it already exists and Create them if required
        $rg,$NewOrOld = Check-If-RG-Exists-And-Create $businessUnit $appID $environment $i $tags $region

    
        if ($NewOrOld -eq "New"){
            
            Write-Host "Since $($RG.ResourceGroupName) is a New Resource Group, applying RBAC, Assigning Policies and SPN if it applies"
            # Set RBAC for the Resource Group
            New-AzureRmRoleAssignment -ObjectId $AADContributorGroup.Id -RoleDefinitionName "Contributor" -Scope $rg.ResourceId -ErrorAction SilentlyContinue
            New-AzureRmRoleAssignment -ObjectId $AADReaderGroup.Id -RoleDefinitionName "Reader" -Scope $rg.ResourceId -ErrorAction SilentlyContinue
            New-AzureRmRoleAssignment -ObjectId $AADAppIDReaderGroup.Id -RoleDefinitionName "Reader" -Scope $rg.ResourceId -ErrorAction SilentlyContinue

            #Technical policy Setup
            New-AzureRMPolicyAssignment -Name "StorageAcctReqHTTPS" -description "Require Secure connection on storage accounts" -Scope $rg.ResourceId -PolicyDefinition $StorageAcctReqHTTPSDefinition

            #Tagging policy setup
            New-AzureRMPolicyAssignment -Name "Tag for BusinessUnit" -Scope $rg.ResourceId  -tagName BusinessUnit -tagValue $BusinessUnit -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for AppID" -Scope $rg.ResourceId  -tagName AppID -tagValue $AppID -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for TenantID" -Scope $rg.ResourceId  -tagName TenantID -tagValue $TenantID -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for BusinessContact" -Scope $rg.ResourceId  -tagName BusinessContact -tagValue $BusinessContact -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for TechnicalContact" -Scope $rg.ResourceId  -tagName TechnicalContact -tagValue $TechnicalContact -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for Environment" -Scope $rg.ResourceId  -tagName Environment -tagValue $Environment -PolicyDefinition $TagDefaultValueDefinition
            New-AzureRMPolicyAssignment -Name "Tag for CostCenter" -Scope $rg.ResourceId  -tagName CostCenter -tagValue $CostCenter -PolicyDefinition $TagDefaultValueDefinition
        
            #Geo-Lockdown policy
            New-AzureRMPolicyAssignment -Name "Geo-Lockdown" -Description "Locks the available locations to be used for deploying resources" -Scope $rg.ResourceId -PolicyDefinition $GeoLockdownDefinition 
    
            if ($SPNPassword -eq ""){
            Write-Host "Skipping SPN assgiment since no password was given"
            break
            }else{
            #Assign SPN to resource group
            $resgrp =  ($rg.ResourceGroupName)        
            #Assign role to SPN to the provided ResourceGroup
            Write-Output "Assigning role $spnRole to SPN App $applicationId and ResourceGroup $resgrp" -Verbose
            New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $applicationId -ResourceGroupName $resgrp -ErrorAction SilentlyContinue
            Write-Output "SPN role assignment completed successfully" -Verbose
            }
            

        }
        else{
        Write-Host "The Resource group $($rg.ResourceGroupName) was found to exist, skipping Policy Assigment, SPN Assigment if it applies and RBAC settings"
        }
    }

    