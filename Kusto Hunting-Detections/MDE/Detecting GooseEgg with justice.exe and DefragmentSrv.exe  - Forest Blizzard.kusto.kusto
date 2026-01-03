// Title: Detecting GooseEgg with justice.exe and DefragmentSrv.exe  - Forest Blizzard    
// Description: This query detects the presence of GooseEgg with justice.exe and DefragmentSrv.exe
// MITRE: T1083, T1053, T1050
// MITRE Tactics: Execution, Collection, Credential Access
// Reference: https://www.microsoft.com/security/blog/2021/11/10/analyzing-gooseegg-a-new-cyberattack-against-ukrainian-organizations/
DeviceProcessEvents
| where TimeGenerated > ago(31d) 
| where InitiatingProcessSHA256 == "6b311c0a977d21e772ac4e99762234da852bbf84293386fbe78622a96c0b052f" or SHA256 == "6b311c0a977d21e772ac4e99762234da852bbf84293386fbe78622a96c0b052f" //hash value of justice.exe
or InitiatingProcessSHA256 == "c60ead92cd376b689d1b4450f2578b36ea0bf64f3963cfa5546279fa4424c2a5" or SHA256 == "c60ead92cd376b689d1b4450f2578b36ea0bf64f3963cfa5546279fa4424c2a5" //hash value of DefragmentSrv.exe
or ProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\servtask.bat /SC MINUTE" or
   ProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\execute.bat /SC MINUTE" or
   ProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\doit.bat /SC MINUTE" or
   ProcessCommandLine contains "schtasks /DELETE /F /TN \\Microsoft\\Windows\\WinSrv" or
   InitiatingProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\servtask.bat /SC MINUTE" or
   InitiatingProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\execute.bat /SC MINUTE" or
   InitiatingProcessCommandLine contains "schtasks /Create /RU SYSTEM /TN \\Microsoft\\Windows\\WinSrv /TR C:\\ProgramData\\doit.bat /SC MINUTE" or
   InitiatingProcessCommandLine contains "schtasks /DELETE /F /TN \\Microsoft\\Windows\\WinSrv"
| project TimeGenerated, AccountName,AccountUpn,ActionType, DeviceId, DeviceName,FolderPath, FileName