# Title: Renamed NirCmd.EXE Execution
# Description: This query detects the execution of NirCmd.exe with a different name.
Get-WinEvent | where {($_.message -match "OriginalFileName.*NirCmd.exe" -and  -not ($_.message -match "Image.*.*\\nircmd.exe" -or $_.message -match "Image.*.*\\nircmdc.exe")) } | select TimeCreated,Id,RecordId,ProcessId,MachineName,Message