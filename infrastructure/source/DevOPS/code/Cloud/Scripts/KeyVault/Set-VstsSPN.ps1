Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "subscription-prod-004" {$VSTSSpnName = ""; Break}           
    "subscription-prod-003" {$VSTSSpnName = ""; Break}           
    "subscription-dev-001" {$VSTSSpnName = ""; Break}       
    "subscription-nonprod-002" {$VSTSSpnName = ""; Break}       
    "subscription-prod-002" {$VSTSSpnName = ""; Break}               
    "CUST-A-EU-PROD-V2" {$VSTSSpnName = ""; Break}           
    "subscription-prod-001" {$VSTSSpnName = ""; Break}        
    "CUST-A-NONPROD-LEARN" {$VSTSSpnName = ""; Break} 
    "subscription-nonprod-001-PAAS" {$VSTSSpnName = ""; Break}
    "CUST-A MyELX" {$VSTSSpnName = ""; Break}
    "subscription-nonprod-003" {$VSTSSpnName = ""; Break} 
    "CUST-A-EU-NONPROD" {$VSTSSpnName = ""; Break}
    "CUST-A-AP-NONPROD" {$VSTSSpnName = ""; Break}     
    "subscription-poc-001" {$VSTSSpnName = ""; Break}
    "subscription-nonprod-001-DATALAKE" {$VSTSSpnName = ""; Break}
    "subscription-nonprod-001" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-CEPLATAM" {$VSTSSpnName = ""; Break}
    "Bobbi Brown" {$VSTSSpnName = ""; Break}
    "MyELC" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PUBLIC" {$VSTSSpnName = ""; Break}
    "CUST-A-NONPROD-SAP" {$VSTSSpnName = ""; Break}
    "CUST-A-PROD-SAP" {$VSTSSpnName = ""; Break}
    "subscription-prod-002-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "subscription-prod-002-O9" {$VSTSSpnName = ""; Break}
    "subscription-prod-002-CEPLATAM" {$VSTSSpnName = ""; Break}
    "subscription-prod-002-DATALAKE" {$VSTSSpnName = ""; Break}
    "subscription-nonprod-001-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "subscription-nonprod-001-E2E" {$VSTSSpnName = ""; Break}
    "subscription-prod-002-E2E" {$VSTSSpnName = ""; Break}
    #"subscription-poc-001-V2" {$VSTSSpnName = ""; Break}           
    "GCCS" {$VSTSSpnName = ""; Break}      
    #"CUST-A-AP-PROD" {$VSTSSpnName = ""; Break}
    #"CUST-A-EU-PROD" {$VSTSSpnName = ""; Break}               
    #"CUST-A APAC PoC" {$VSTSSpnName = ""; Break}
    #"CUST-A APAC Public" {$VSTSSpnName = ""; Break}
    #"CUST-A App Dev Migration" {$VSTSSpnName = ""; Break}
    #"CUST-A-AM-DR-C2M" {$VSTSSpnName = ""; Break}
    #"CUST-A-AM-Security-POC" {$VSTSSpnName = ""; Break}
    #"CUST-A-AP-POC" {$VSTSSpnName = ""; Break}  
    #"CUST-A-EU-POC" {$VSTSSpnName = ""; Break}
    #"CUST-A-Windows-Analytics" {$VSTSSpnName = ""; Break}
    #"HCLTools" {$VSTSSpnName = ""; Break}
    #"SAP" {$VSTSSpnName = ""; Break}            
    #"CUST-A-GLOBAL-OPERATIONS" {{$VSTSSpnName = ""; Break}   
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Subscription is not valid or does not have a VSTS SPN"
   }
}
    
Write-Host $VSTSSpnName

# set vsts variable
Write-Output "##vso[task.setvariable variable=VSTSSpnName]$($VSTSSpnName)"
