# Title: Potentially Suspicious Child Process of KeyScrambler
# Description: This query identifies potentially suspicious child processes of KeyScrambler.
# Reference: https://www.carbonblack.com/2017/08/10/definitive-guide-incident-response-2017/
Get-WinEvent | where {($_.message -match "ParentImage.*.*\\KeyScrambler.exe" -and (($_.message -match "Image.*.*\\cmd.exe" -or $_.message -match "Image.*.*\\cscript.exe" -or $_.message -match "Image.*.*\\mshta.exe" -or $_.message -match "Image.*.*\\powershell.exe" -or $_.message -match "Image.*.*\\pwsh.exe" -or $_.message -match "Image.*.*\\regsvr32.exe" -or $_.message -match "Image.*.*\\rundll32.exe" -or $_.message -match "Image.*.*\\wscript.exe") -or ($_.message -match "Cmd.Exe" -or $_.message -match "cscript.exe" -or $_.message -match "mshta.exe" -or $_.message -match "PowerShell.EXE" -or $_.message -match "pwsh.dll" -or $_.message -match "regsvr32.exe" -or $_.message -match "RUNDLL32.EXE" -or $_.message -match "wscript.exe"))) } | select TimeCreated,Id,RecordId,ProcessId,MachineName,Message