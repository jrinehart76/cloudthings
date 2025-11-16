Param(
    [parameter(Mandatory=$true)][string]$Subscription
)

# select LogAnalytics workspace and resource group based off subscription
switch ($Subscription) {
    "subscription-prod-004" {$LogAnalyticsWorkspace = "la-prod-learn"; $LogAnalyticsResourceGroup ="RG-PROD-LEARN-MGMT"; Break}           
    "subscription-prod-003" {$LogAnalyticsWorkspace = "la-ap-southeastasia-prod-v2"; $LogAnalyticsResourceGroup ="rg-region2-SoutheastAsia-Prod-V2-MGMT"; Break}           
    "subscription-dev-001" {$LogAnalyticsWorkspace = "la-am-eastus-devopspoc"; $LogAnalyticsResourceGroup ="rg-region1-DevOpsPOC-Mgmt"; Break}       
    "subscription-nonprod-002" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod-v2"; $LogAnalyticsResourceGroup ="rg-region2-SoutheastAsia-NONPROD-V2-Mgmt"; Break}       
    "subscription-prod-002" {$LogAnalyticsWorkspace = "la-am-eastus-Prod"; $LogAnalyticsResourceGroup ="rg-region1-Prod-Mgmt"; Break}               
    "CUST-A-EU-PROD-V2" {$LogAnalyticsWorkspace = "la-eu-uksouth-prod-v2"; $LogAnalyticsResourceGroup ="rg-region3-prod-v2-mgmt"; Break}           
    "subscription-prod-001" {$LogAnalyticsWorkspace = "la-am-eastus-prod-paas"; $LogAnalyticsResourceGroup ="rg-region1-prod-paas-mgmt"; Break}         
    "CUST-A-NONPROD-LEARN" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-learn"; $LogAnalyticsResourceGroup ="rg-nonprod-learn-mgmt"; Break}        
    "subscription-nonprod-001-PAAS" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-PaaS"; $LogAnalyticsResourceGroup ="rg-region1-nonprod-paas-mgmt"; Break}       
    "CUST-A MyELX" {$LogAnalyticsWorkspace = "la-am-eastus-prod-myelx"; $LogAnalyticsResourceGroup ="rg-region1-myelx-mgmt"; Break}                
    "subscription-nonprod-003" {$LogAnalyticsWorkspace = "la-eu-uksouth-nonprod-v2"; $LogAnalyticsResourceGroup ="rg-region3-UKSouth-NonProd-V2-MGMT"; Break}        
    "CUST-A-EU-NONPROD" {$LogAnalyticsWorkspace = "la-eu-weurope-NonProd"; $LogAnalyticsResourceGroup ="rg-region3-UKSouth-NonProd-Mgmt"; Break}           
    "CUST-A-AP-NONPROD" {$LogAnalyticsWorkspace = "la-ap-southeastasia-nonprod"; $LogAnalyticsResourceGroup ="rg-region2-nonprod-mgmt"; Break}            
    "subscription-poc-001" {$LogAnalyticsWorkspace = "la-am-eastus-POC"; $LogAnalyticsResourceGroup ="rg-region1-POC-Mgmt"; Break}               
    "subscription-nonprod-001-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-DataLake"; $LogAnalyticsResourceGroup ="rg-region1-NonProd-DataLake-Mgmt"; Break}  
    "subscription-nonprod-001" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd"; $LogAnalyticsResourceGroup ="rg-region1-NonProd-Mgmt"; Break}
    "CUST-A-AM-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-NonProd-CEPLATAM"; $LogAnalyticsResourceGroup ="rg-region1-NonProd-CEPLATAM-Mgmt"; Break}          
    "Bobbi Brown" {$LogAnalyticsWorkspace = "la-am-eastus-bobbibrown-mgmt"; $LogAnalyticsResourceGroup ="rg-region1-BobbiBrown-Mgmt"; Break}              
    "MyELC" {$LogAnalyticsWorkspace = "la-AM-EastUS-MyELC"; $LogAnalyticsResourceGroup ="rg-region1-MyELC-MGMT"; Break}                    
    "CUST-A-AM-PUBLIC" {$LogAnalyticsWorkspace = "la-am-eastus-Public"; $LogAnalyticsResourceGroup ="rg-region1-Public-Mgmt"; Break}             
    "CUST-A-NONPROD-SAP" {$LogAnalyticsWorkspace = "la-nonprod-sap"; $LogAnalyticsResourceGroup ="rg-nonprod-sap-mgmt"; Break}           
    "CUST-A-PROD-SAP" {$LogAnalyticsWorkspace = "la-prod-sap"; $LogAnalyticsResourceGroup ="rg-prod-sap-mgmt"; Break}             
    "subscription-prod-002-CORNERSTONE" {$LogAnalyticsWorkspace = "la-prod-cornerstone"; $LogAnalyticsResourceGroup ="rg-prod-cornerstone-mgmt"; Break}   
    "subscription-prod-002-O9" {$LogAnalyticsWorkspace = "la-am-eastus-prod-o9"; $LogAnalyticsResourceGroup ="rg-region1-prod-o9-mgmt"; Break}            
    "subscription-prod-002-CEPLATAM" {$LogAnalyticsWorkspace = "la-am-eastus-Prod-CEPLATAM"; $LogAnalyticsResourceGroup ="rg-region1-Prod-CEPLATAM-Mgmt"; Break}      
    "subscription-prod-002-DATALAKE" {$LogAnalyticsWorkspace = "la-am-eastus-prod-edlna"; $LogAnalyticsResourceGroup ="rg-region1-prod-edlna-mgmt"; Break}     
    "subscription-nonprod-001-CORNERSTONE" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-cornerstone"; $LogAnalyticsResourceGroup ="rg-region1-nonprod-cornerstone-mgmt"; Break}
    "subscription-nonprod-001-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-nonprod-e2e"; $LogAnalyticsResourceGroup ="rg-region1-nonprod-e2e-mgmt"; Break}  
    "subscription-prod-002-E2E" {$LogAnalyticsWorkspace = "la-am-eastus-prod-e2e"; $LogAnalyticsResourceGroup ="rg-region1-prod-e2e-mgmt"; Break}
    "CUST-A-CN-PROD" {$LogAnalyticsWorkspace = "la-cn-chinaeast2-prod"; $LogAnalyticsResourceGroup ="RG-CN-ChinaEast2-Prod-Mgmt"; Break}  
    #"subscription-poc-001-V2" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}            
    #"GCCS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                      
    #"CUST-A-AP-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}              
    #"CUST-A-EU-PROD" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                        
    #"CUST-A APAC PoC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}             
    #"CUST-A APAC Public" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}          
    #"CUST-A App Dev Migration" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
    #"CUST-A-AM-DR-C2M" {$LogAnalyticsWorkspace = "LogAnalytics-AM-EastUS-DR-C2M"; $LogAnalyticsResourceGroup ="rg-region1-dr-c2m-azuremgmt"; Break}            
    #"CUST-A-AM-Security-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}      
    #"CUST-A-AP-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"CUST-A-EU-POC" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}               
    #"CUST-A-Windows-Analytics" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}    
    #"HCLTools" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}  
    #"SAP" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}                       
    #"CUST-A-GLOBAL-OPERATIONS" {$LogAnalyticsWorkspace = ""; $LogAnalyticsResourceGroup =""; Break}     
   default {        
       $ErrorActionPreference = "Stop"
       Write-Error "$Subscription is not valid or does not have a matching Log Analytics Workspace"
   }
}
    
Write-Host $LogAnalyticsWorkspace
Write-Host $LogAnalyticsResourceGroup

# set vsts variable
Write-Output "##vso[task.setvariable variable=LogAnalyticsWorkspace]$($LogAnalyticsWorkspace)"
Write-Output "##vso[task.setvariable variable=LogAnalyticsResourceGroup]$($LogAnalyticsResourceGroup)"
