$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"

Set-ItemProperty -Path $path -Name "fSingleSessionPerUser" -Value 0 -Force
Set-ItemProperty -Path $path -Name "fDenyTSConnections" -Value 0 -Force

Write-Host "Multiple RDP sessions enabled. Restarting services..."

Restart-Service TermService -Force
