param (
    [string]$ResourceGroupName,
    [string[]]$VMNames,
    [string]$ServiceNowUrl,
    [string]$ServiceNowUser,
    [string]$ServiceNowPassword,
    [string]$TemplateFile = "./CMDB_CI_Template_v1.2.xlsx"
)

"gwmi win32_bios | fl SerialNumber" | Out-File ./windows-sn.ps1 -Force
"dmidecode -s system-serial-number" | Out-File ./linux-sn.sh -Force
$subName = (Get-AzContext).Subscription.Name
[System.Collections.ArrayList]$vmoutput = @()
Select-AzSubscription -SubscriptionName GCCS
Write-Output "Retrieving shared images..."
$i = 4
$images = Get-AzGalleryImageDefinition -GalleryName SharedImageGalleryAMEastUSSS -ResourceGroupName rg-region1-SS-Images
Write-Output "Retrieving subscription information..."

$subs = Get-AzSubscription | ? { $_.Name -eq $subName }
foreach($sub in $subs) {
    [System.Collections.ArrayList]$jobs = @()
    Select-AzSubscription -SubscriptionName $sub.Id
    # Grab inventory first
    Write-Output "Gathering VM inventory for $($sub.Name) ($($sub.Id))..."
    if($ResourceGroupName -eq "" -or $ResourceGroupName -eq $null){
        $vms = Get-AzVM -Status | ? { $_.ResourceGroupName -notlike "MC_*" }
    } else {
        $vms = Get-AzVM -Status | ? { $_.ResourceGroupName -eq $ResourceGroupName }
    }
    $vms = $vms  | select -Property `
    @{N='name';E={$_.Name}}, `
    @{N='asset_tag';E={$_.Name}}, `
    @{N='company';E={'cdd12e384f120600de34a9d18110c7f4'}}, `
    @{N='category';E={'Server'}}, `
    @{N='subcategory';E={"$($_.storageProfile.osDisk.osType) Server"}}, `
    @{N='u_status';E={ if($_.PowerState -like "*running") { return "Deployed" } else { return "Decommissioned"} }}, `
    @{N='u_sub_status';E={'Functional'}}, `
	@{N='u_site_category';E={'Cloud'}}, `
    @{N='u_support_owner';E={'Epstein, Erik'}}, `
    @{N='u_business_owner';E={$_.tags.BusinessOwner}}, `
    @{N='cost_center';E={$_.tags.CostCenter}}, `
    @{N='ip_address';E={'NA'}}, `
    @{N='used_for';E={ switch($_.tags.Environment.ToLower()) { "dev" { return "Development" }; "qa" { return "QA" }; "prod" { return "Production" }; default { return "Development" }; }  }}, `
    @{N='u_region';E={'Cloud Data Centre'}}, `
    @{N='u_country';E={'Cloud Data Centre'}}, `
    @{N='u_city';E={'Cloud Data Center'}}, `
    @{N='location';E={'Cloud Data Center'}}, `
	@{N='os';E={ "$($_.storageProfile.osDisk.osType)" }}, `
    @{N='os_version';E={ if([string]::IsNullOrEmpty($_.storageProfile.imageReference.Sku)) { return "None" } else { return $_.storageProfile.imageReference.Sku } }}, `
    @{N='virtual';E={"true"}}, `
    @{N='serial_number';E={'NA'}}, `
    @{N='manufacturer';E={'Microsoft Corporation'}}, `
    @{N='model_id';E={'Azure'}}, `
    @{N='supported_by';E={'ManagedServiceProvider'}}, `
	@{N='u_support_company';E={'ManagedServiceProvider'}}, `
    @{N='support_group';E={'Customer-CloudOps-ManagedServices-G'}}, `
    @{N='u_pci';E={"false"} }, `
    @{N='u_sox';E={"false"}}, ` 
    @{N='u_type';E={"$($_.storageProfile.osDisk.osType) Server"}}, `
    @{N='u_ownership_type';E={'CUST-A Owned'}}, `
    @{N='discovery_source';E={"MSP"}}, `
    @{N='ResourceGroupName';E={$_.ResourceGroupName}}, `
    @{N='NicID';E={$_.networkProfile.networkInterfaces[0].Id}}, `
    @{N='ImageId';E={$_.storageProfile.imageReference.Id}}

    # Grab IPs
    Write-Output "Grabbing network interfaces..."
    $nics = Get-AzNetworkInterface | Select -Property `
    @{N='Id';E={$_.Id}}, `
    @{N='IP';E={$_.IpConfigurations[0].PrivateIpAddress}}
    # Filter the list if VM names are supplied
    if($VMNames -ne $null -or $VMNames.Count -gt 0) {
        $vms = $vms | ? { $_.Name -in $VMNames }
    }

    # Grab serial number
    foreach($vm in $vms) {
        if($vm.u_status -eq "Deployed") {
            Write-Output "Getting serial number for $($vm.name)..."
            if($vm.SubCategory -eq "Linux Server") {
                $output = Invoke-AzVmRunCommand -CommandId RunShellScript -VMName $vm.name -ResourceGroupName $vm.ResourceGroupName -ScriptPath ./linux-sn.sh
                $CmdbClassName = "cmdb_ci_linux_server"
            } else {
                $output = Invoke-AzVmRunCommand -CommandId RunPowerShellScript -VMName $vm.name -ResourceGroupName $vm.ResourceGroupName -ScriptPath ./windows-sn.ps1
                $CmdbClassName = "cmdb_ci_win_server"
            }
            Write-Output "Updating records for $($vm.name)..."
            $vm.serial_number = $output.Value[0].Message.Split(":")[1].Replace("`n","").Replace("[stdout]","").Replace("[stderr]","").Trim()
            $nic = ($nics | ? { $_.Id -eq $vm.NicID})
            if($nic -ne $null) {
                $vm.ip_address = $nic.IP
            } else {
                Write-Warning "Could not find private IP for VM $($vm.Name)."
            }            
        }

        if($vm.OSVersion -eq "None" -or $vm.OSVersion -eq $null) {
            $osname = ($images | ? { $vm.ImageId -like "$($_.Id)*" }).Identifier.Offer.Replace("Server","")
            $osver = ($images | ? { $vm.ImageId -like "$($_.Id)*" }).Identifier.Sku
            $vm.os_version = "$($osname) $($osver)"
        }

        $password = ConvertTo-SecureString -String "$($ServiceNowPassword)" -AsPlainText -Force
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceNowUser, $password

		$vminfo = ($vm | select name,company,asset_tag,u_type,category,short_description,subcategory,cost_center,u_status,u_sub_status,u_support_owner,u_site_category,u_business_owner,ip_address,used_for,u_region,u_country,u_city,location,os,os_version,virtual,serial_number,manufacturer,model_id,supported_by,u_support_company,support_group,u_pci,u_sox,u_ownership_type,discovery_source)
		$vminfo = $vminfo | ConvertTo-Json -Depth 25
		$duplicatevmip = irm -Method Get -Uri "$($ServiceNowUrl)/api/now/table/$($CmdbClassName)?ip_address=$($nic.IP)" -Credential $cred -ContentType "application/json" | ConvertTo-Json -Depth 50
		if($duplicatevmip.Contains("ip_address") -eq $True){
			
			write-host "VM Record Already Exists, Patching"
			
			### Get Sys ID
			$GetSysid = irm -Method Get -Uri "$($ServiceNowUrl)/api/now/table/$($CmdbClassName)?ip_address=$($nic.IP)" -Credential $cred -ContentType "application/json" 
			$SysID = $GetSysid.result.sys_id
			
			### Patch Record
			$result = irm -Method Patch -Uri "$($ServiceNowUrl)/api/now/table/$($CmdbClassName)/$($SysID)" -Credential $cred -Body "$($vminfo)" -ContentType "application/json" -Verbose
			Write-Output $result | ConvertTo-Json -Depth 50
			Write-Output "VM Record Update Complete for $($vm.name)."
			
		}else{
			$result = irm -Method Post -Uri "$($ServiceNowUrl)/api/now/table/$($CmdbClassName)" -Credential $cred -Body "$($vminfo)" -ContentType "application/json" -Verbose
			Write-Output $result | ConvertTo-Json -Depth 50
			Write-Output "VM Record Created for $($vm.name)."
		}

    }
    
}


