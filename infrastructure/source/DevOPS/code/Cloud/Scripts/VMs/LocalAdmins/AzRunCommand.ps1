param(
[string[]]$ADGroupName,
[string]$Region
)

([adsi]"WinNT://./Administrators,group").ADD('WinNT://elcompanies/U-ELC-CloudOps')
([adsi]"WinNT://./Administrators,group").ADD('WinNT://elcompanies/U-ELC-CloudManagedServices')
foreach($group in $ADGroupName){
    if($ADGroupName.StartsWith('U-')){
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://elcompanies/$($ADGroupName)")
	}else{
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://$($Region)/$($ADGroupName)")
	}
}


