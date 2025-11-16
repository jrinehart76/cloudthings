param(
[string[]]$ADGroupName,
[string]$Region
)

([adsi]"WinNT://./Administrators,group").ADD('WinNT://elcompanies/U-CUST-A-CloudOps')
([adsi]"WinNT://./Administrators,group").ADD('WinNT://elcompanies/U-CUST-A-CloudManagedServices')
foreach($group in $ADGroupName){
    if($ADGroupName.StartsWith('U-')){
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://elcompanies/$($ADGroupName)")
	}else{
		([adsi]"WinNT://./Administrators,group").ADD("WinNT://$($Region)/$($ADGroupName)")
	}
}


