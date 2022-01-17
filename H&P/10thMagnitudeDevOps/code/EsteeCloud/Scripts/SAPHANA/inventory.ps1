$sub = Select-AzSubscription -SubscriptionName ELC-EU-NONPROD-V2
$vms = Get-AzVM -ResourceGroupName "RG-EU-UKSouth-Dev-SAPTND"
# Create dynamic hosts file for Ansible
$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("all:") | Out-Null
$sb.AppendLine("hosts:".PadLeft(8)) | Out-Null
foreach($vm in $vms) {
  $nic = Get-AzNetworkInterface -Name $vm.NetworkProfile.NetworkInterfaces[0].Id.Split("/")[-1] -ResourceGroupName $vm.ResourceGroupName
  $IP = $nic.IpConfigurations.PrivateIpAddress
  $sb.AppendLine("".PadLeft(4) + "$($vm.Name):") | Out-Null
  $sb.AppendLine("".PadLeft(6) + "ansible_connection: ssh") | Out-Null
  $sb.AppendLine("".PadLeft(6) + "ansible_host: " + $IP) | Out-Null
}
$sb.AppendLine("".PadLeft(2) + "vars:") | Out-Null
$sb.AppendLine("".PadLeft(4) + "ansible_ssh_user: sapinstall") | Out-Null
$sb.AppendLine("".PadLeft(4) + "ansible_ssh_pass: ") | Out-Null

$sb.ToString() | Out-File ./inventory.yml
