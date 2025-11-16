net localgroup administrators AM\kbrinkle /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-CEPAPAC-Devs'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://customer-a-domain/U-Customer-CEPAPAC-Admins'); }"
