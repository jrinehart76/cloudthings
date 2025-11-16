Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "CUST-A-PROD-LEARN" {$VSTSSpnName = ""; Break}           
    "CUST-A-AP-PROD-V2" {$VSTSSpnName = ""; Break}           
    "CUST-A-AM-POC-DevOps" {$VSTSSpnName = ""; Break}       
    "CUST-A-AP-NONPROD-V2" {$VSTSSpnName = ""; Break}       
    "CUST-A-AM-PROD" {$VSTSSpnName = ""; Break}               
    "CUST-A-EU-PROD-V2" {$VSTSSpnName = ""; Break}           
    "CUST-A-AM-PROD-PAAS" {$VSTSSpnName = ""; Break}        
    "CUST-A-NONPROD-LEARN" {$VSTSSpnName = ""; Break} 
    "CUST-A-AM-NONPROD-PAAS" {$VSTSSpnName = ""; Break}
    "CUST-A MyELX" {$VSTSSpnName = ""; Break}
    "CUST-A-EU-NONPROD-V2" {$VSTSSpnName = ""; Break} 
    "CUST-A-EU-NONPROD" {$VSTSSpnName = ""; Break}
    "CUST-A-AP-NONPROD" {$VSTSSpnName = ""; Break}     
    "CUST-A-AM-POC" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-NONPROD-DATALAKE" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-NONPROD" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-CEPLATAM" {$VSTSSpnName = ""; Break}
    "Bobbi Brown" {$VSTSSpnName = ""; Break}
    "MyELC" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PUBLIC" {$VSTSSpnName = ""; Break}
    "CUST-A-NONPROD-SAP" {$VSTSSpnName = ""; Break}
    "CUST-A-PROD-SAP" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PROD-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PROD-O9" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PROD-CEPLATAM" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PROD-DATALAKE" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-NONPROD-CORNERSTONE" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-NONPROD-E2E" {$VSTSSpnName = ""; Break}
    "CUST-A-AM-PROD-E2E" {$VSTSSpnName = ""; Break}
    #"CUST-A-AM-POC-V2" {$VSTSSpnName = ""; Break}           
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
