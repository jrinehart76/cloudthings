net localgroup administrators AM\10thMagnitudeDevOps /add	#don't work'
net localgroup administrators AM\10thMagnitudeSupport /add #don't work
net localgroup administrators customer-a-domain\U-Customer-EDLNAAdmin /add
net localgroup administrators customer-a-domain\U-Customer-EDLGlobalAdmin /add
net localgroup administrators customer-a-domain\sa-am-tableau-qa /add

net localgroup administrators customer-a-domain\U-Customer-EDLNADev_All /add
net localgroup administrators customer-a-domain\U-Customer-EDLNADev_Fin /add
net localgroup administrators customer-a-domain\U-Customer-EDLNADev_DTC /add
net localgroup administrators customer-a-domain\U-Customer-EDLNADev_HR /add
net localgroup administrators customer-a-domain\U-Customer-EDLNADev_SC /add
net localgroup administrators customer-a-domain\U-Customer-EDLNADev_CsMkt /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_All'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_Fin'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_DTC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_HR'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_SC'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-EDLGlobalDev_CsMkt'); }"
