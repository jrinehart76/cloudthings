#!/bin/bash
echo '$(sapInstallPassword) | Out-File $(System.ArtifactsDirectory)/ansible/psfl.txt

$vms = Get-AzureRmVM -ResourceGroupName $(ResourceGroupName)
# Create dynamic hosts file for Ansible
$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("all:") | Out-Null
$sb.AppendLine("hosts:".PadLeft(8)) | Out-Null
foreach($vm in $vms) {
  $sb.AppendLine("".PadLeft(4) + "$($vm.Name):" | Out-Null
  $sb.AppendLine("".PadLeft(6) + "ansible_connection: ssh") | Out-Null
  $sb.AppendLine("".PadLeft(6) + "ansible_host: " + ) | Out-Null
}
$sb.AppendLine("".PadLeft(2) + "vars:") | Out-Null
$sb.AppendLine("".PadLeft(4) + "ansible_ssh_user: sapinstall") | Out-Null
$sb.AppendLine("".PadLeft(4) + "ansible_ssh_pass: $(sapInstallPassword)") | Out-Null

$sb.ToString() | Out-File $(System.ArtifactsDirectory)/ansible/inventory.yml' > ./inventory.ps1

pwsh -f ./inventory.ps1