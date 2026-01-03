<#
.SYNOPSIS
    New Country Sign-in Detection Script

.DESCRIPTION
    This script provide Microsoft Entra ID sign-in logs to detect when users 
    sign in from new countries they haven't accessed before. It analyzes successful 
    sign-in attempts over the last 30 days and alerts when a user's latest sign-in 
    comes from a country not seen in their previous sign-in history.

    The script performs the following analysis:
    - Retrieves successful sign-in logs from the last 30 days using Microsoft Graph API
    - Groups sign-ins by user principal name
    - Compares each user's latest sign-in country with their historical countries
    - Generates alerts for users signing in from previously unseen countries
    - Provides detailed information about the new country sign-in events

    This helps identify potential account compromise, unauthorized access, or users 
    traveling to new locations that may require security verification.

.PARAMETER StartDate
    The script automatically sets the start date to 30 days ago from the current date.
    Modify the AddDays(-30) value in the script to change the historical analysis period.

.EXAMPLE
    .\Detect-NewCountrySignins.ps1
    Analyzes sign-in logs from the last 30 days and reports users signing in from new countries

.NOTES
    Script Name    : Detect-NewCountrySignins.ps1
    Version        : 1.1
    Author         : Elli Shlomo
    Purpose        : Part of the EntraID Incident Response Scripts (EIDIR) collection
    
    Prerequisites:
    - Microsoft.Graph PowerShell module
    - AuditLog.Read.All permission scope
    - Global Reader, Security Reader, or Reports Reader role (minimum)

    Performance Notes:
    - Uses paging to handle large datasets efficiently
    - Filters are applied server-side where possible
    - Local filtering used for complex logic to reduce API calls

.LINK
https://github.com/eshlomo1/CloudSec/new/main/CFIR%20(Cloud%20IR)/EntraID/EIDIR    
    
.COMPONENT
    Microsoft Graph API, Entra ID Security Monitoring
    
#>
# ========================================
# SCRIPT CONFIGURATION
# ========================================

Import-Module Microsoft.Graph

# Connect with required scope (AuditLog.Read.All)
Connect-MgGraph -Scopes AuditLog.Read.All

# Configuration
$monitorIntervalMinutes = 10      # How often to check (in minutes)
$lookbackDays = 30                # How far back to query sign-ins

function Get-SignIns {
    param($since)

    $startDate = $since.ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
    $filter = "createdDateTime ge $startDate"
    $encodedFilter = [System.Web.HttpUtility]::UrlEncode($filter)
    $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?\$filter=$encodedFilter&`$top=999"

    $allLogs = @()
    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        $allLogs += $response.value
        $uri = $response.'@odata.nextLink'
    } while ($uri)

    return $allLogs
}

function Monitor-NewCountrySignins {
    param($logs)

    $successLogs = $logs | Where-Object { $_.status.status -eq 'Success' }
    $logsByUser = $successLogs | Group-Object -Property userPrincipalName

    foreach ($userGroup in $logsByUser) {
        $user = $userGroup.Name
        $userLogs = $userGroup.Group | Sort-Object createdDateTime -Descending

        if ($userLogs.Count -lt 2) { continue }

        $latestCountry = $userLogs[0].location.countryOrRegion
        $previousCountries = $userLogs | Select-Object -Skip 1 | Where-Object { $_.location -and $_.location.countryOrRegion } | Select-Object -ExpandProperty location | Select-Object -ExpandProperty countryOrRegion -Unique

        if ($previousCountries -notcontains $latestCountry) {
            Write-Host "[ALERT] User $user signed in from NEW country: $latestCountry at $($userLogs[0].createdDateTime)"
            # Additional output or integrations can be added here
        }
    }
}

function Monitor-MultipleFailedSignins {
    param($logs)

    $logsByUser = $logs | Group-Object -Property userPrincipalName

    foreach ($userGroup in $logsByUser) {
        $user = $userGroup.Name
        $userLogs = $userGroup.Group | Sort-Object createdDateTime

        $failures = $userLogs | Where-Object { $_.status.status -ne 'Success' }
        $successes = $userLogs | Where-Object { $_.status.status -eq 'Success' }

        if ($failures.Count -ge 3 -and $successes) {
            Write-Host "[ALERT] User $user had $($failures.Count) failed sign-in attempts followed by success."
            # Additional output or integrations can be added here
        }
    }
}

function Monitor-RiskySignins {
    param($logs)

    $riskyLogs = $logs | Where-Object {
        $_.riskLevelAggregated -and $_.riskLevelAggregated -ne 'none'
    }

    foreach ($log in $riskyLogs) {
        Write-Host "[ALERT] Risky sign-in detected for user $($log.userPrincipalName) - Risk Level: $($log.riskLevelAggregated) at $($log.createdDateTime)"
        # Additional output or integrations can be added here
    }
}

while ($true) {
    Write-Host "Starting Entra ID IR monitoring check at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    $since = (Get-Date).AddDays(-$lookbackDays)
    $logs = Get-SignIns -since $since

    Monitor-NewCountrySignins -logs $logs
    Monitor-MultipleFailedSignins -logs $logs
    Monitor-RiskySignins -logs $logs

    Write-Host "Sleeping for $monitorIntervalMinutes minutes..."
    Start-Sleep -Seconds ($monitorIntervalMinutes * 60)
}
