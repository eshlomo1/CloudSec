<#
.SYNOPSIS
    Detects multiple failed sign-in attempts followed by a successful sign-in using Microsoft Graph sign-in logs.

.DESCRIPTION
    This script analyzes Microsoft Entra ID (Azure AD) sign-in logs via Microsoft Graph to identify users who have three or more consecutive failed sign-in attempts immediately followed by a successful sign-in. Such patterns may indicate account compromise or brute-force attempts.

    The script performs the following steps:
    - Connects to Microsoft Graph with AuditLog.Read.All scope
    - Retrieves sign-in logs from the last 30 days
    - Groups logs by user principal name
    - Detects sequences of 3+ failed sign-ins followed by a success
    - Outputs details of the failed attempts and the subsequent successful sign-in

.PARAMETER startDate
    The script automatically sets the start date to 30 days ago. Adjust the AddDays(-30) value to change the analysis window.

.EXAMPLE
    .\Detect-MultipleFailedSignins.ps1
    Runs the detection for the last 30 days and outputs suspicious sign-in patterns.

.NOTES
    Script Name    : Detect-MultipleFailedSignins.ps1
    Version        : 1.0
    Author         : Elli Shlomo
    Purpose        : Part of the EntraID Incident Response Scripts (EIDIR) collection
    
    Prerequisites:
    - Microsoft.Graph PowerShell module
    - AuditLog.Read.All permission scope
    - Global Reader, Security Reader, or Reports Reader role (minimum)

.LINK
    https://github.com/eshlomo1/CloudSec/tree/main
    https://cyberdom.blog/entra-id-inciden…shell-techniques/
    
.COMPONENT
    Microsoft Graph API, Entra ID Security Monitoring
    
#>

# ========================================
# SCRIPT CONFIGURATION
# ========================================

# Ensure Microsoft.Graph module is installed
# Install-Module Microsoft.Graph -Scope CurrentUser

Import-Module Microsoft.Graph

Connect-MgGraph -Scopes AuditLog.Read.All

$startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssK")
$filter = "createdDateTime ge $startDate"
$encodedFilter = [System.Web.HttpUtility]::UrlEncode($filter)
$uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?\$filter=$encodedFilter&`$top=999"

$allLogs = @()

do {
    $response = Invoke-MgGraphRequest -Method GET -Uri $uri
    $allLogs += $response.value
    $uri = $response.'@odata.nextLink'
} while ($uri)

Write-Host "Fetched $($allLogs.Count) sign-in records from last 30 days."

$filteredLogs = $allLogs | Where-Object { $_.status.errorCode -ne $null }

$logsByUser = $filteredLogs | Group-Object -Property userPrincipalName

foreach ($userGroup in $logsByUser) {
    $user = $userGroup.Name
    $events = $userGroup.Group | Sort-Object createdDateTime

    $failureBatch = @()
    foreach ($event in $events) {
        if ($event.status.errorCode -ne 0) {
            $failureBatch += $event
        }
        elseif ($event.status.errorCode -eq 0 -and $failureBatch.Count -ge 3) {
            Write-Output "User $user had $($failureBatch.Count) failed attempts followed by a successful sign-in at $($event.createdDateTime)."

            Write-Output "Failed attempts details:"
            $failureBatch | Select-Object `
                @{Name="Time";Expression={$_.createdDateTime}}, `
                @{Name="FailureReason";Expression={$_.status.failureReason}}, `
                @{Name="IP Address";Expression={$_.ipAddress}}, `
                @{Name="Location";Expression={$_.location.city + ', ' + $_.location.countryOrRegion}}, `
                @{Name="App";Expression={$_.appDisplayName}}, `
                @{Name="Device";Expression={$_.deviceDetail.operatingSystem}}, `
                @{Name="Client App";Expression={$_.clientAppUsed}} | Format-Table -AutoSize

            Write-Output "Successful sign-in details:"
            $event | Select-Object `
                @{Name="Time";Expression={$_.createdDateTime}}, `
                @{Name="IP Address";Expression={$_.ipAddress}}, `
                @{Name="Location";Expression={$_.location.city + ', ' + $_.location.countryOrRegion}}, `
                @{Name="App";Expression={$_.appDisplayName}}, `
                @{Name="Device";Expression={$_.deviceDetail.operatingSystem}}, `
                @{Name="Client App";Expression={$_.clientAppUsed}}, `
                @{Name="Authentication Details";Expression={$_.authenticationMethods -join ', '}}, `
                @{Name="Risk Level";Expression={$_.riskLevelAggregated}} | Format-List

            Write-Output "--------------------------------------"
            $failureBatch = @()
        }
        elseif ($event.status.errorCode -eq 0) {
            $failureBatch = @()
        }
    }
}

