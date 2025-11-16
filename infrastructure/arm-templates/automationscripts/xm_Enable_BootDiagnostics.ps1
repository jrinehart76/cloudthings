<#
    .DESCRIPTION
        Enables boot diagnostics for resources in subscription or optionally by resource group

        Runs from an Azure Automation account.

    .PREREQUISITES
        Existing AzureRunAsAccount in Automations account

    .DEPENDENCIES
        Az.Accounts
        Az.Resources

    .TODO

    .NOTES
        
    .CHANGELOG

    .VERSION
        1.0.0
#>

Param (
    [Parameter(Mandatory=$True)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$False)]
    [string]$ResourceGroupName
)

#Connect as automation SPN goes here
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

$StorageAccount = Get-AzStorageAccount -ErrorAction 'SilentlyContinue' | Where-Object {$_.StorageAccountName -eq $StorageAccountName}

# Check if storage account exists
if ($StorageAccount) {
    Write-Output "${StorageAccountName} storage account exists. Proceeding..."
} else {
    Write-Error "${StorageAccountName} storage account doesn't exist. Please verify the storage account exists within your subscription."
    return
}

$Machines = Get-AzVM -ResourceGroupName $ResourceGroupName -Status | Where-Object {$_.Tags["MSPMonitored"] -eq 'y'}

ForEach ($Machine in $Machines) {
    if (!$Machine.DiagnosticsProfile.BootDiagnostics.Enabled) {
        Write-Output "[$($Machine.Name)] Boot diagnostics are not installed. Starting job..."
        $Resource = Get-AzResource -ResourceName $Machine.Name -ResourceGroupName $Machine.ResourceGroupName -ExpandProperties
        $Resource.Properties.diagnosticsProfile.bootDiagnostics.enabled = 'True'
        $Resource.Properties.diagnosticsProfile.BootDiagnostics.storageUri = $storageaccount.PrimaryEndpoints.Blob
        $Resource | Set-AzResource -Force
    } else {
        Write-Output "[$($Machine.Name)] Boot diagnostics are already enabled."
    }
}
