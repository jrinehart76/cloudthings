<#
    .DESCRIPTION
        Configures an Azure Automation Hybrid Worker

    .PREREQUISITES
        Log Analytics Workspace
        Azure Automation Account
        Virtual Machine

    .DEPENDENCIES
        Az.Resources

    .PARAMETER groupName 
        The hybrid worker group name -- will create a new group if one does not exist
    .PARAMETER aaEndpoint 
        The Azure Automation Endpoint URL
    .PARAMETER aaKey 
        The Azure Automation Account Primary (or Secondary) Key

    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.3.30

    .CHANGELOG

    .VERSION
        1.0.0
#>

param (
    [Parameter(Mandatory=$True)]
    [String]$groupName,

    [Parameter(Mandatory=$True)]
    [String]$aaEndpoint,

    [Parameter(Mandatory=$True)]
    [String]$aaKey
)

# Get the folder name of the latest agent version
$baseFolder = "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation"
$version = Get-ChildItem -Path $baseFolder | Sort-Object -Property Name -Descending | Select -First 1 | Select Name -ExpandProperty Name

# Create Hybrid Worker
cd "C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation\$version\HybridRegistration"
Import-Module .\HybridRegistration.psd1
Add-HybridRunbookWorker -GroupName $groupName -EndPoint $aaEndpoint -Token $aaKey

# Install Powershell Modules
Install-PackageProvider -Name "Nuget" -RequiredVersion "2.8.5.208" -Force
Install-Module Az,SqlServer -Force

# Configure Orchestrator to support Az.Storage commands
$strOrchestratorSandboxDirectory = (Get-ChildItem -Path $baseFolder -Filter 'Orchestrator.Sandbox.exe' -Recurse).Directory.FullName
$strOrchestratorSandboxConfigName = 'Orchestrator.Sandbox.exe.config'
$fullPath = $strOrchestratorSandboxDirectory + '/' + $strOrchestratorSandboxConfigName
###See https://github.com/Azure/azure-powershell/issues/8531
$objCustomXML = '<configuration><runtime><AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=false" /></runtime></configuration>'
Out-File -FilePath $fullPath -InputObject $objCustomXML