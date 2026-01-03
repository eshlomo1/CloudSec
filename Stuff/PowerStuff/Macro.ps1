# Office versions to simulate
$versions = "14.0", "15.0", "16.0"

foreach ($v in $versions) {

    # Sandbox path that LOOKS like the real Office path
    $p = "HKCU:\Software\Microsoft\Office\$v\SecurityTestEmu"

    # Ensure key exists
    if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }

    # Create noise to mimic AccessVBOM tampering
    New-ItemProperty -Path $p -Name "AccessVBOM"   -Value 1 -PropertyType DWORD -Force | Out-Null

    # Create noise to mimic VbaWarnings tampering
    New-ItemProperty -Path $p -Name "VbaWarnings"  -Value 1 -PropertyType DWORD -Force | Out-Null

    # Additional noise keys to resemble malware / macro weaponization
    New-ItemProperty -Path $p -Name "MacroPolicyOverride" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $p -Name "VBEBypassFlag"       -Value 1 -PropertyType DWORD -Force | Out-Null
}

Write-Host "Macro-security tampering executed."
