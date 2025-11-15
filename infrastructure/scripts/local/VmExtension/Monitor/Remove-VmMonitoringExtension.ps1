
# Install-VmMonitoringExtension -WorkspaceName 'prd-oms-rm' -Location 'eastus2'
param (
    $WorkspaceCustomerId,
    $Location
)

#declare global variables
$ExtensionName = 'MonitoringAgent'

#get a list of all VMs
Write-Output "Getting a list of all virtual machines."
$Resources = Get-AzVM -Location $Location -Status

# If there are no VMs, do not continue
if (!$Resources) {
    Write-Error "There was a problem retrieving machines for [$($Location)]. Exception: $($Error[0])"
    return
}

ForEach ($Resource in $Resources) {
    if ($Resource.Name.StartsWith("aks-")) {
        Write-Output "[$($Resource.Name)] is an AKS node. Skipping..."
    }
    else {
        $VMEx = Get-AzVMExtension `
                    -ResourceGroupName $Resource.ResourceGroupName `
                    -VMName $Resource.Name `
                    -Name $ExtensionName `
                    -ErrorAction "SilentlyContinue"
        if ($VMEx) {
            $workspaceId = $VMEx.PublicSettings | ConvertFrom-Json | Select-Object workspaceId -ExpandProperty workspaceId
            if ($workspaceId -ne $WorkspaceCustomerId) {
                Write-Output "[$($Resource.Name)] Connected to a different workspace - [$($workspaceId)]"
                Write-Output "[$($Resource.Name)] Removing from workspace [$($workspaceId)]"
                Remove-AzVMExtension `
                    -ResourceGroupName $Resource.ResourceGroupName `
                    -VMName $Resource.Name `
                    -Name $ExtensionName `
                    -Force `
                    -ErrorAction "SilentlyContinue" | Out-Null
                if ($?) {
                    Write-Output "[$($Resource.Name)] Successfully removed from workspace [$($workspaceId)]"
                } else {
                    Write-Error "[$($Resource.Name)] Unable to remove from workspace [$($workspaceId)]. Check the VM logs."
                }
            } elseif ($workspaceId -eq $WorkspaceCustomerId) {
                Write-Output "[$($Resource.Name)] Already connected to workspace [$($workspaceId)] Skipping..."
            }
        }
        else { Write-Output "[$($Resource.Name)] Does not have the monitoring agent extension installed" }
    }
}