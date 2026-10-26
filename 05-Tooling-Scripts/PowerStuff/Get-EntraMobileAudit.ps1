# Connect with required read permissions for both directory and audit logs
Connect-MgGraph -Scopes "Device.Read.All", "AuditLog.Read.All", "Directory.Read.All"

# 1. Pull the Entra ID mobile device inventory
Write-Host "Fetching registered mobile devices..." -ForegroundColor Cyan
$RegisteredDevices = Get-MgDevice -All | Where-Object { $_.OperatingSystem -match "iOS|Android" }

# Create a lookup hash table using DeviceId or DisplayName for fast correlation
$DeviceMap = @{}
foreach ($dev in $RegisteredDevices) {
    if ($dev.DeviceId) {
        $DeviceMap[$dev.DeviceId] = $dev
    }
}

# 2. Fetch recent mobile sign-in logs
Write-Host "Fetching mobile sign-in logs..." -ForegroundColor Cyan
$SignIns = Get-MgAuditLogSignIn -All -Top 500 | Where-Object { 
    $_.DeviceDetail.OperatingSystem -match "iOS|Android" -or 
    $_.ClientAppUsed -match "Mobile" 
}

# 3. Join sign-in activity with master device inventory data
$CombinedReport = foreach ($si in $SignIns) {
    $devId = $si.DeviceDetail.DeviceId
    $matchedDevice = if ($devId -and $DeviceMap.ContainsKey($devId)) { $DeviceMap[$devId] } else { $null }

    [PSCustomObject]@{
        UserPrincipalName        = $si.UserPrincipalName
        AppDisplayName           = $si.AppDisplayName
        ClientAppUsed            = $si.ClientAppUsed
        LastSignInDateTime       = $si.CreatedDateTime
        IPAddress                = $si.IpAddress
        Location                 = "$($si.Location.City), $($si.Location.CountryOrRegion)"
        
        # From Sign-In Log DeviceDetail
        SignInOS                 = $si.DeviceDetail.OperatingSystem
        SignInDeviceName         = $si.DeviceDetail.DisplayName
        SignInTrustType          = $si.DeviceDetail.TrustType
        IsCompliant              = $si.DeviceDetail.IsCompliant
        
        # Enriched from Master Device Inventory (Get-MgDevice)
        RegisteredDeviceId       = $devId
        MasterOSVersion          = $matchedDevice.OperatingSystemVersion
        MasterTrustType          = $matchedDevice.TrustType
        MasterIsCompliant        = $matchedDevice.IsCompliant
        ApproximateLastSignIn    = $matchedDevice.ApproximateLastSignInDateTime
        IsRegisteredInDirectory  = $(if ($matchedDevice) { "Yes" } else { "No (Unmanaged/External)" })
    }
}

# Output results
$CombinedReport | Out-GridView -Title "Entra ID Mobile Device Inventory & Sign-In Correlation"
# Or export to CSV:
# $CombinedReport | Export-Csv -Path "MobileDeviceSignIns.csv" -NoTypeInformation
