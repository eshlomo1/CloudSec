<#
.SYNOPSIS
    Detects and analyzes OAuth application consents in Microsoft Entra ID.

.DESCRIPTION
    This script monitors and analyzes OAuth application consent grants in Microsoft Entra ID (Azure AD)
    to identify potentially suspicious or unauthorized application consents. It helps security teams 
    detect possible OAuth-based attacks where users might have granted access to malicious applications.

.PARAMETER UserPrincipalName
    The user principal name to investigate. If not provided, script will analyze consents from all users.

.PARAMETER DaysBack
    Number of days to look back for consent activities. Default is 30 days.

.EXAMPLE
    .\Get-SuspiciousOAuthConsents.ps1 -UserPrincipalName "user@contoso.com"
    Analyzes OAuth consents granted by a specific user

.EXAMPLE
    .\Get-SuspiciousOAuthConsents.ps1 -DaysBack 7
    Analyzes all OAuth consents from the last 7 days

.NOTES
    Script Name    : Get-SuspiciousOAuthConsents.ps1
    Version       : 1.1
    Author        : Elli Shlomo
    
    Prerequisites:
    - Microsoft.Entra PowerShell module
    - AuditLog.Read.All or Directory.Read.All permissions
    - Global Reader, Security Reader, or Reports Reader role (minimum)
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory=$false)]
    [int]$DaysBack = 30
)

function Format-ConsentDetails {
    param (
        [Parameter(Mandatory=$true)]
        [object]$ConsentEvent
    )
    
    # Extract Application info from TargetResources
    $appInfo = $ConsentEvent.TargetResources | Where-Object { $_.type -eq 'ServicePrincipal' -or $_.type -eq 'Application' }
    
    # Extract permissions or any other relevant details from AdditionalDetails
    $permissions = $ConsentEvent.AdditionalDetails | Where-Object { $_.key -eq 'PermissionList' } | Select-Object -ExpandProperty value -ErrorAction SilentlyContinue
    
    # Extract Client App and User-Agent from AdditionalDetails
    $clientApp = $ConsentEvent.AdditionalDetails | Where-Object { $_.key -eq 'Client App' } | Select-Object -ExpandProperty value -ErrorAction SilentlyContinue
    $userAgent = $ConsentEvent.AdditionalDetails | Where-Object { $_.key -eq 'User-Agent' } | Select-Object -ExpandProperty value -ErrorAction SilentlyContinue
    
    # Extract InitiatedBy user and app display names safely
    $initiatedByUser = if ($ConsentEvent.initiatedBy.user) { $ConsentEvent.initiatedBy.user.userPrincipalName } else { 'N/A' }
    $initiatedByApp = if ($ConsentEvent.initiatedBy.app) { $ConsentEvent.initiatedBy.app.displayName } else { 'N/A' }

    return [PSCustomObject]@{
        Time             = $ConsentEvent.activityDateTime
        User             = $initiatedByUser
        Application      = if ($appInfo) { $appInfo.displayName } else { 'N/A' }
        AppID            = if ($appInfo) { $appInfo.id } else { 'N/A' }
        Permissions      = if ($permissions) { $permissions } else { 'N/A' }
        ClientApp        = if ($clientApp) { $clientApp } else { 'N/A' }
        UserAgent        = if ($userAgent) { $userAgent } else { 'N/A' }
        Result           = $ConsentEvent.result
        ResultReason     = $ConsentEvent.resultReason
        CorrelationId    = $ConsentEvent.correlationId
        Category         = $ConsentEvent.category
        OperationType    = $ConsentEvent.operationType
        LoggedByService  = $ConsentEvent.loggedByService
        InitiatedByApp   = $initiatedByApp
    }
}

try {
    Import-Module Microsoft.Entra -ErrorAction Stop

    # Connect to Microsoft Graph if not connected
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All"
    }

    $startDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $filter = "ActivityDisplayName eq 'Consent to application' and ActivityDateTime ge $startDate"

    if ($UserPrincipalName) {
        $filter += " and InitiatedByUser/userPrincipalName eq '$UserPrincipalName'"
    }

    Write-Host "Retrieving OAuth consent events from the past $DaysBack days..." -ForegroundColor Cyan
    $consentLogs = Get-EntraAuditDirectoryLog -Filter $filter -All

    if ($consentLogs.Count -eq 0) {
        Write-Host "No OAuth consent events found for the specified criteria." -ForegroundColor Yellow
        exit
    }

    Write-Host "Found $($consentLogs.Count) consent events. Processing details..." -ForegroundColor Green
    $formattedResults = $consentLogs | ForEach-Object { Format-ConsentDetails -ConsentEvent $_ }

    $formattedResults | Sort-Object Time -Descending | Format-Table -AutoSize

    $csvPath = "OAuthConsents_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $formattedResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Results exported to: $csvPath" -ForegroundColor Green

} catch {
    Write-Error "An error occurred: $_"
}
