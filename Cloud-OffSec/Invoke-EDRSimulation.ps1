# Advanced SentinelOne EDR simulation: LSASS handle access, memory read, and simulated process injection
# Run as Administrator for best results

function Invoke-EDRSimulation {
    <#
    .SYNOPSIS
        Simulates advanced attacker behaviors: LSASS handle access, memory read, and process injection.
    .DESCRIPTION
        - Opens a handle to LSASS (mimics credential dumping).
        - Attempts to read memory from LSASS (no real secrets accessed).
        - Simulates process injection by allocating and writing memory in LSASS (no code execution).
        - All actions are performed in-memory; no disk artifacts are created.
    #>

    # Get LSASS process
    $lsass = Get-Process -Name lsass -ErrorAction SilentlyContinue
    if (-not $lsass) {
        Write-Output "LSASS process not found. Are you running on Windows?"
        return
    }

    # Define Win32 APIs in-memory
    $sig = @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesRead);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out int lpNumberOfBytesWritten);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }
"@
    Add-Type -TypeDefinition $sig

    # Access rights
    $PROCESS_ALL_ACCESS = 0x1F0FFF

    # Open LSASS with all access (should trigger EDR)
    $hProcess = [Win32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $lsass.Id)
    if ($hProcess -eq [IntPtr]::Zero) {
        Write-Output "Failed to open LSASS handle. Access denied or insufficient privileges."
        return
    }
    Write-Output "Opened handle to LSASS (simulated credential dump)."

    # Attempt to read memory (simulate credential access)
    $buffer = New-Object byte[] 64
    $bytesRead = 0
    $success = [Win32]::ReadProcessMemory($hProcess, [IntPtr]0x10000, $buffer, $buffer.Length, [ref]$bytesRead)
    if ($success) {
        Write-Output "Simulated memory read from LSASS ($bytesRead bytes)."
    } else {
        Write-Output "Failed to read LSASS memory (expected if not admin)."
    }

    # Simulate process injection (allocate and write memory)
    $mem = [Win32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, 0x100, 0x1000, 0x40)
    if ($mem -ne [IntPtr]::Zero) {
        $shellcode = [byte[]](1..16) # Dummy data, not real shellcode
        $bytesWritten = 0
        $wSuccess = [Win32]::WriteProcessMemory($hProcess, $mem, $shellcode, $shellcode.Length, [ref]$bytesWritten)
        if ($wSuccess) {
            Write-Output "Simulated process injection: wrote $bytesWritten bytes to LSASS."
        } else {
            Write-Output "Failed to write to LSASS memory."
        }
    } else {
        Write-Output "Failed to allocate memory in LSASS."
    }

    # Clean up
    [Win32]::CloseHandle($hProcess)
    Write-Output "Simulation complete. Check SentinelOne console for detection/alerts."
}

# Run the simulation (in-memory only, no disk touch)
Invoke-AdvancedEDRSimulation
