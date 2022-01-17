 <#
    .DESCRIPTION
        Gathers Update Management troubleshooting information from Windows VMs

    .PREREQUISITES
        Minimum Operating - System Windows 2008 R2

    .DEPENDENCIES
        None
        
    .TODO
        None

    .NOTES
        AUTHOR: dnite
        LASTEDIT: 2020.2.26

    .CHANGELOG

    .VERSION
        1.0.0

#> 

param(
    [string]$automationAccountLocation,
    [switch]$returnCompactFormat,
    [switch]$returnAsJson
)

$location = switch ( $automationAccountLocation ) {
        "australiasoutheast"{ "ase"  }
        "canadacentral"     { "cc"   }
        "centralindia"      { "cid"  }
        "eastus2"           { "eus2" }
        "japaneast"         { "jpe"  }
        "northeurope"       { "ne"   }
        "southcentralus"    { "scus" }
        "southeastasia"     { "sea"  }
        "uksouth"           { "uks"  }
        "westcentralus"     { "wcus" }
        "westeurope"        { "we"   }

        default             { "eus2" }
}

function New-RuleCheckResult
{
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$ruleId,
        [string]$ruleName,
        [string]$ruleDescription,
        [string]$result,
        [string]$resultMessage,
        [string]$ruleGroupId = $ruleId,
        [string]$ruleGroupName,
        [string]$resultMessageId = $ruleId,
        [array]$resultMessageArguments = @()
    )

    if ($returnCompactFormat.IsPresent) {
        $compactResult = [pscustomobject] @{
            'RuleId'= $ruleId
            'RuleGroupId'= $ruleGroupId
            'CheckResult'= $result
            'CheckResultMessageId'= $resultMessageId
            'CheckResultMessageArguments'= $resultMessageArguments
        }
        return $compactResult
    }

    # $fullResult = [pscustomobject] @{
    #     'RuleId'= $ruleId
    #     'RuleGroupId'= $ruleGroupId
    #     'RuleName'= $ruleName
    #     'RuleGroupName' = $ruleGroupName
    #     'RuleDescription'= $ruleDescription
    #     'CheckResult'= $result
    #     'CheckResultMessage'= $resultMessage
    #     'CheckResultMessageId'= $resultMessageId
    #     'CheckResultMessageArguments'= $resultMessageArguments
    # }

    $fullResult = "{`"RuleId`": `"$ruleId`", `"CheckResult`": `"$result`"}"
    return $fullResult
}

function checkRegValue
{
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$path,
        [string][Parameter(Mandatory=$true)]$name,
        [int][Parameter(Mandatory=$true)]$valueToCheck
    )

    $val = Get-ItemProperty -path $path -name $name -ErrorAction SilentlyContinue
    if($val.$name -eq $null) {
        return $null
    }

    if($val.$name -eq $valueToCheck) {
        return $true
    } else {
        return $false
    }
}

function getRegValue
{
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$true)]$path,
        [string][Parameter(Mandatory=$true)]$name
    )

    $val = Get-ItemProperty -path $path -name $name -ErrorAction SilentlyContinue
    if($val.$name -eq $null) {
        return $null
    } else {
        return $val
    }
}

function Validate-OperatingSystem {
    $osRequirementsLink = "https://docs.microsoft.com/azure/automation/automation-update-management#supported-client-types"

    $ruleId = "OperatingSystemCheck"
    $ruleName = "Operating System"
    $ruleDescription = "The Windows Operating system must be version 6.1.7601 (Windows Server 2008 R2 SP1) or higher"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()
    $version = [System.Environment]::OSVersion.Version

    if($version -ge [System.Version]"6.1.7601") {
        $result = $version
        $resultMessage = "Operating System version is supported"
    } else {
        $result = $version
        $resultMessage = "Operating System version is not supported. Supported versions listed here: $osRequirementsLink"
        $resultMessageArguments += $osRequirementsLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-NetFrameworkInstalled {
    $netFrameworkDownloadLink = "https://www.microsoft.com/net/download/dotnet-framework-runtime"

    $ruleId = "DotNetFrameworkInstalledCheck"
    $ruleName = ".Net Framework 4.5+"
    $ruleDescription = ".NET Framework version 4.5 or higher is required"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    # https://docs.microsoft.com/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
    $dotNetFullRegistryPath = "HKLM:SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full"
    if((Get-ChildItem $dotNetFullRegistryPath -ErrorAction SilentlyContinue) -ne $null) {
        $versionCheck = (Get-ItemProperty $dotNetFullRegistryPath).Release
        if($versionCheck -ge 378389) {
            $result = $versionCheck
            $resultMessage = ".NET Framework version 4.5+ is found"
        } else {
            $result = $versionCheck
            $resultMessage = ".NET Framework version 4.5 or higher is required: $netFrameworkDownloadLink"
            $resultMessageArguments += $netFrameworkDownloadLink
        }
    } else{
        $result = $versionCheck
        $resultMessage = ".NET Framework version 4.5 or higher is required: $netFrameworkDownloadLink"
        $resultMessageArguments += $netFrameworkDownloadLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-WmfInstalled {
    $wmfDownloadLink = "https://www.microsoft.com/download/details.aspx?id=54616"
    $ruleId = "WMFInstalledCheck"
    $ruleName = "WMF 5.1"
    $ruleDescription = "Windows Management Framework version 4.0 or higher is required (version 5.1 or higher is preferable)"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"   

    $psVersion = $PSVersionTable.PSVersion
    $resultMessageArguments = @() + $psVersion

    if($psVersion -ge 5.1) {
        $result = $psVersion
        $resultMessage = "Detected Windows Management Framework version: $psVersion"
    } else {
        $result = $psVersion
        $resultMessage = "Detected Windows Management Framework version: $psVersion. Version 4.0 or higher is required (version 5.1 or higher is preferable): $wmfDownloadLink"
        $resultMessageArguments += $wmfDownloadLink
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-TlsEnabled {
    $ruleId = "TlsVersionCheck"
    $ruleName = "TLS 1.2"
    $ruleDescription = "Client and Server connections must support TLS 1.2"
    $result = $null
    $reason = ""
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"

    $tls12RegistryPath = "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\SecurityProviders\\SCHANNEL\\Protocols\\TLS 1.2\\"
    $serverEnabled =     checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "Enabled" 1
    $ServerNotDisabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "DisabledByDefault" 0
    $clientEnabled =     checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "Enabled" 1
    $ClientNotDisabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "DisabledByDefault" 0

    $ServerNotEnabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "Enabled" 0
    $ServerDisabled =   checkRegValue ([System.String]::Concat($tls12RegistryPath, "Server")) "DisabledByDefault" 1
    $ClientNotEnabled = checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "Enabled" 0
    $ClientDisabled =   checkRegValue ([System.String]::Concat($tls12RegistryPath, "Client")) "DisabledByDefault" 1

    if ([System.Environment]::OSVersion.Version -lt [System.Version]"6.1.7601") {
        $result = "Disabled"
        $resultMessageId = "$ruleId.$result"
        $resultMessage = "TLS 1.2 is not enabled by default on the Operating System. Follow the instructions to enable it: https://support.microsoft.com/help/4019276/update-to-add-support-for-tls-1-1-and-tls-1-2-in-windows"
    } elseif([System.Environment]::OSVersion.Version -ge [System.Version]"6.1.7601" -and [System.Environment]::OSVersion.Version -le [System.Version]"6.1.8400") {
        if($ClientNotDisabled -and $ServerNotDisabled -and !($ServerNotEnabled -and $ClientNotEnabled)) {
            $result = "Enabled"
            $resultMessage = "TLS 1.2 is enabled on the Operating System."
            $resultMessageId = "$ruleId.$result"
        } else {
            $result = "Disabled"
            $reason = "NotExplicitlyEnabled"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is not enabled by default on the Operating System. Follow the instructions to enable it: https://docs.microsoft.com/windows-server/security/tls/tls-registry-settings#tls-12"
        }
    } elseif([System.Environment]::OSVersion.Version -ge [System.Version]"6.2.9200") {
        if($ClientDisabled -or $ServerDisabled -or $ServerNotEnabled -or $ClientNotEnabled) {
            $result = "Disabled"
            $reason = "ExplicitlyDisabled"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is supported by the Operating System, but currently disabled. Follow the instructions to re-enable: https://docs.microsoft.com/windows-server/security/tls/tls-registry-settings#tls-12"
        } else {
            $result = "Enabled"
            $reason = "EnabledByDefault"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "TLS 1.2 is enabled by default on the Operating System."
        }
    } else {
        $result = "Disabled"
        $reason = "NoDefaultSupport"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Your OS does not support TLS 1.2 by default."
    }

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId
}

function Validate-MmaIsRunning {
    $mmaServiceName = "HealthService"
    $mmaServiceDisplayName = "Microsoft Monitoring Agent"

    $ruleId = "MonitoringAgentServiceRunningCheck"
    $ruleName = "Monitoring Agent service status"
    $ruleDescription = "$mmaServiceName must be running on the machine"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "servicehealth"
    $ruleGroupName = "VM Service Health Checks"
    $resultMessageArguments = @() + $mmaServiceDisplayName + $mmaServiceName

    if(Get-Service -Name $mmaServiceName -ErrorAction SilentlyContinue| Where-Object {$_.Status -eq "Running"} | Select-Object) {
        $result = "Running"
        $resultMessage = "$mmaServiceDisplayName service ($mmaServiceName) is running"
    } else {
        $result = "NotRunning"
        $resultMessage = "$mmaServiceDisplayName service ($mmaServiceName) is not running"
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-MmaEventLogHasNoErrors {
    $mmaServiceName = "Microsoft Monitoring Agent"
    $logName = "Operations Manager"
    $eventId = 4502

    $ruleId = "MonitoringAgentServiceEventsCheck"
    $ruleName = "Monitoring Agent service events"
    $ruleDescription = "Event Log must not have event 4502 logged in the past 24 hours"
    $result = $null
    $reason = ""
    $resultMessage = $null
    $ruleGroupId = "servicehealth"
    $ruleGroupName = "VM Service Health Checks"
    $resultMessageArguments = @() + $mmaServiceName + $logName + $eventId

    $OpsMgrLogExists = [System.Diagnostics.EventLog]::Exists($logName);
    if($OpsMgrLogExists) {
        $event = Get-EventLog -LogName "Operations Manager" -Source "Health Service Modules" -After (Get-Date).AddHours(-24) | where {$_.eventID -eq $eventId}
        if($event -eq $null) {
            $result = "Passed"
            $resultMessageId = "$ruleId.$result"
            $resultMessage = "$mmaServiceName service Event Log ($logName) does not have event $eventId logged in the last 24 hours."
        } else {
            $result = "Failed"
            $reason = "EventFound"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "$mmaServiceName service Event Log ($logName) has event $eventId logged in the last 24 hours. Look at the results of other checks to troubleshoot the reasons."
        }
    } else {
        $result = "Failed"
        $reason = "NoLog"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "$mmaServiceName service Event Log ($logName) does not exist on the machine"
    }

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-MachineKeysFolderAccess {
    $folder = "C:\\ProgramData\\Microsoft\\Crypto\\RSA\\MachineKeys"

    $ruleId = "CryptoRsaMachineKeysFolderAccessCheck"
    $ruleName = "Crypto RSA MachineKeys Folder Access"
    $ruleDescription = "SYSTEM account must have WRITE and MODIFY access to '$folder'"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "permissions"
    $ruleGroupName = "Access Permission Checks"
    $resultMessageArguments = @() + $folder

    $User = $env:UserName
    $permission = (Get-Acl $folder).Access | ? {($_.IdentityReference -match $User) -or ($_.IdentityReference -match "Everyone")} | Select IdentityReference, FileSystemRights
    if ($permission) {
        $result = "Passed"
        $resultMessage = "Have permissions to access $folder"
    } else {
        $result = "Failed"
        $resultMessage = "Missing permissions to access $folder"
    }
    $resultMessageId = "$ruleId.$result"

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-MmaWorkspaceId {
    $ruleId = "WrkspId"
    $ruleName = "Monitoring Agent Connected Workspace Id"
    $ruleDescription = "Monitoring Agent must be connected to a workspace"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "workspace"
    $ruleGroupName = "Workspace"
    $resultMessageArguments = @()

    $AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg -ErrorAction SilentlyContinue
    
    If ($AgentCfg.GetCloudWorkspaces()) {
        If ($($AgentCfg.GetCloudWorkspaces()).Count -gt 1) {
            $wscount = $($AgentCfg.GetCloudWorkspaces()).Count
            $result = "MultipleWorkspace"
            $reason = "MultipleWorkspaceFound"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "Agent is connected to $wscount workspaces"
        } Else {
            $result = $AgentCfg.GetCloudWorkspaces() | Select-Object -expand workspaceid
            $reason = "WorkspaceFound"
            $resultMessageId = "$ruleId.$result.$reason"
            $resultMessage = "Agent is connected to $result"
        }
    } Else { 
        $result = 'Missing' 
        $reason = "WorkspaceNotFound"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Agent is not connected to a workspace"
    }
    
    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-WindowsUpdateEnabled {
    $ruleId = "WindowsUpdateConfig"
    $ruleName = "Windows Update Configuration"
    $ruleDescription = "Windows Update Must Be Configured"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    $wuBaseRegistryPath = "HKLM:\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate"
    $WUEnabled = getRegValue $wuBaseRegistryPath "DisableWindowsUpdateAccess"

    if($WUEnabled -eq 0) {
        $result = "WindowsUpdateEnabled"
        $reason = "WindowsUpdateEnabled"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Windows Update is Enabled"
    } else {
        $result = "WindowsUpdateDisabled"
        $reason = "WindowsUpdateDisabled"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Windows Update is Disabled"
    }
    
    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-WindowsUpdateOption {
    $ruleId = "WindowsUpdateOption"
    $ruleName = "Windows Update Download Option"
    $ruleDescription = "Windows Update Download Option Must Be Configured"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    $wuAuRegistryPath = "HKLM:\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
    $WUOption =  getRegValue $wuAuRegistryPath "AUOptions"

    if ($WUOption.AUOptions -eq $null) {
        $result = "NotConfigured"
    } else {
        $result = $WUOption.AUOptions
        $reason = "AllOptionsConfigured"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Windows Update configuration"
    }
    
    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

function Validate-WindowsUpdateLocation {
    $ruleId = "WindowsUpdateLocation"
    $ruleName = "Windows Update Location"
    $ruleDescription = "Windows Update Location Must Be Configured"
    $result = $null
    $resultMessage = $null
    $ruleGroupId = "prerequisites"
    $ruleGroupName = "Prerequisite Checks"
    $resultMessageArguments = @()

    $wuAuRegistryPath = "HKLM:\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
    $WULocation = getRegValue $wuAuRegistryPath "UseWUServer"

    if ($WULocation.UseWUServer) {
        $result = $WULocation.UseWUServer
        $reason = "Configured"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Windows Update Location is correctly configured"
    } else {
        $result = "NotConfigured"
        $reason = "NotConfigured"
        $resultMessageId = "$ruleId.$result.$reason"
        $resultMessage = "Windows Update Location is not correctly configured"
    }

    return New-RuleCheckResult $ruleId $ruleName $ruleDescription $result $resultMessage $ruleGroupId $ruleGroupName $resultMessageId $resultMessageArguments
}

$osResults = Validate-OperatingSystem
$dotnetResults = Validate-NetFrameworkInstalled
$wmfResults = Validate-WmfInstalled
$agentResults = Validate-MmaIsRunning
$logResults = Validate-MmaEventLogHasNoErrors
$permResults = Validate-MachineKeysFolderAccess
$tlsResults = Validate-TlsEnabled
$wrkspResults = Validate-MmaWorkspaceId
$wuEnabledResults = Validate-WindowsUpdateEnabled
$wuOptionResults = Validate-WindowsUpdateOption
$wuLocationResults = Validate-WindowsUpdateLocation


$validationResults = "[`n" + $osResults + ",`n" + $dotnetResults + ",`n" + $wmfResults + ",`n" + $agentResults + ",`n" + $logResults + ",`n" + $permResults + ",`n" + $tlsResults + ",`n" + $wrkspResults + ",`n" + $wuEnabledResults + ",`n" + $wuOptionResults + ",`n" + $wuLocationResults + "`n]"

if($returnAsJson.IsPresent) {
    return ConvertTo-Json $validationResults -Compress
} else {
    return $validationResults
} 
