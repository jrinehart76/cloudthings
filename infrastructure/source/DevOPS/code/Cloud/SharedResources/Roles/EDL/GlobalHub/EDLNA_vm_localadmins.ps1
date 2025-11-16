net localgroup administrators customer-a-domain\U-Customer-EDLNAAdmin /add
net localgroup administrators customer-a-domain\U-Customer-EDLGlobalAdmin /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_All'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_Fin'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_DTC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_HR'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_SC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_CsMkt'); }"
