<#
    .DESCRIPTION
        Enable diagnostic settings for each resource.
        Runs from an Azure Automation account.

    .PREREQUISITES
        Existing AzureRunAsAccount in Automations account

    .DEPENDENCIES
        Az.Accounts
        Az.Resources
        Az.OperationalInsights
        Az.Monitor

    .TODO
        Add option to filter on tagging

    .NOTES
        AUTHOR: cherbison, jrinehart
        LASTEDIT: 2019.7.2

    .CHANGELOG

    .VERSION
        1.0.0
#>

##gather parameters
param (
    [Parameter(Mandatory=$True)]
    $WorkspaceName,
    
    [Parameter(Mandatory=$False)]
    $ResourceGroupName
)

##connect as the azure automation run-as account user
$DiagnosticSettingName = "diagnostics"
$ConnectionName = 'AzureRunAsConnection'
$AutomationConnection = Get-AutomationConnection -Name $ConnectionName

Try {
    $Connection = Connect-AzAccount `
        -CertificateThumbprint $AutomationConnection.CertificateThumbprint `
        -ApplicationId $AutomationConnection.ApplicationId `
        -Tenant $AutomationConnection.TenantId `
        -ServicePrincipal
}
Catch {
    if (!$Connection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

##declare variables and assign values
$Workspace = Get-AzOperationalInsightsWorkspace | Where-Object {$_.Name -eq $WorkspaceName}

##get the list of resources
if ($ResourceGroupName) {
    $Resources = Get-AzResource -ResourceGroup $ResourceGroupName
} else {
    $Resources = Get-AzResource
}

##if no resources found, return
if (!($Resources)) {
    Write-Error "Resources is null. Please check if resources exist for given ResourceGroup or ResourceType."
    return
}

##configure diagnostics settings for all resources
ForEach ($Resource in $Resources) {
    Try {
        $DiagnosticSettings = Get-AzDiagnosticSetting -ResourceId $Resource.ResourceId -ErrorAction 'Stop'
    } Catch {
        if ($_.Exception.ToString().Contains("BadRequest")) {
            Write-Output "Cannot enable diagnostic settings on [$($Resource.Name)]."
            Continue
        }
    }

    if (!($DiagnosticSettings)) {
        Write-Output "Enabling metrics and logs with default categories on [$($Resource.Name)]."
        Set-AzDiagnosticSetting -Name $DiagnosticSettingName `
            -WorkspaceId $Workspace.ResourceId `
            -ResourceId $Resource.ResourceId `
            -Enabled $True `
            -ErrorAction 'Continue' | Set-AzResource -ResourceId $Resource.ResourceId -Force
    } else {
        Write-Output "Diagnostic settings already exist on [$($Resource.Name)] : $($DiagnosticSettings.Name -Join ',')."
    }
}
