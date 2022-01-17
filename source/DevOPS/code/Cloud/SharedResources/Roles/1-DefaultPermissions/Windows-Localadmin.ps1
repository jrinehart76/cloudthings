net localgroup administrators AM\kbrinkle /add
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://AM/G-AM-Cornerstone-NonProd'); }"
powershell -command "& { ([adsi]'WinNT://./administrators,group').Add('WinNT://AM/G-AM-Cornerstone-NonProd-Admin'); }"
