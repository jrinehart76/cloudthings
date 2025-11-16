param(
[string[]]$ADGroupName,
[string]$Region
)

([adsi]"WinNT://./Administrators,group").ADD('WinNT://customer-a-domain/U-Customer-CloudOps')
([adsi]"WinNT://./Administrators,group").ADD('WinNT://customer-a-domain/U-Customer-CloudManagedServices')
foreach($group in $ADGroupName){
    if($ADGroupName.StartsWith('U-')){
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://customer-a-domain/$($ADGroupName)")
	}else{
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://$($Region)/$($ADGroupName)")
	}
}


