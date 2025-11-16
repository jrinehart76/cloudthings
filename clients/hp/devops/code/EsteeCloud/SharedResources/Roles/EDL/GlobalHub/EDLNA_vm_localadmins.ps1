net localgroup administrators elcompanies\U-CUST-A-EDLNAAdmin /add
net localgroup administrators elcompanies\U-CUST-A-EDLGlobalAdmin /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_All'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_Fin'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_DTC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_HR'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_SC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://elcompanies/U-CUST-A-EDLGlobalDev_CsMkt'); }"
