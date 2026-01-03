$fakeIn = "$env:TEMP\fake_dump.bin"
"xyz" | Out-File $fakeIn -Encoding ASCII -Force

$h = "SAM", "SYSTEM", "SECURITY"

foreach ($item in $h) {
    1..3 | ForEach-Object {
        Start-Process "cmd.exe" -ArgumentList "/c certutil.exe encode `"$fakeIn`" `"C:\Windows\System32\config\$item`"" `
            -WindowStyle Hidden
    }
}

Write-Host "Concurrent certutil emulation launched."
 
