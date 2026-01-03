<#
.SYNOPSIS
    Detect-LegacyAuthSignIns.ps1 - Identifies successful sign-ins using legacy authentication protocols in Microsoft Entra ID.

.DESCRIPTION
    This script monitors and detects successful sign-ins to Microsoft Entra ID (Azure AD) that use 
    legacy authentication protocols. Legacy authentication poses security risks as it bypasses 
    modern security features like multi-factor authentication and conditional access policies.

    Monitored Legacy Protocols:
    - Other clients (Basic Auth)
    - Exchange ActiveSync
    - IMAP
    - POP3
    - MAPI over HTTP
    - Offline address book

    The script provides detailed information about each legacy auth sign-in:
    - User identity (Display Name, UPN)
    - Protocol used
    - IP address
    - Timestamp
    - Geographic location (City, Country)
    - Device details

    This helps security teams:
    - Identify users still relying on legacy authentication
    - Track geographic locations of legacy auth usage
    - Plan migration to modern authentication
    - Investigate potential security risks

.PARAMETER None
    This script does not accept parameters. It retrieves all sign-in logs and filters
    for successful legacy authentication attempts.

.EXAMPLE
    .\Detect-LegacyAuthSignIns.ps1
    Displays all successful legacy authentication sign-ins sorted by date.

.NOTES
    Script Name    : Detect-LegacyAuthSignIns.ps1
    Version       : 1.0
    Author        : Elli Shlomo
    Purpose       : Part of the EntraID Incident Response Scripts (EIDIR) collection
    
    Prerequisites:
    - Microsoft.Entra PowerShell module
    - AuditLog.Read.All permission scope
    - Global Reader, Security Reader, or Reports Reader role (minimum)

.COMPONENT
    Microsoft Entra ID
#>

# ========================================
# SCRIPT CONFIGURATION AND EXECUTION
# ========================================

# Detect successful sign-ins using legacy authentication protocols
$legacyProtocols = @(
    'Other clients',
    'Exchange ActiveSync',
    'IMAP',
    'POP3',
    'MAPI over HTTP',
    'Offline address book'
)

Get-EntraAuditSignInLog -All |
Where-Object {
    $_.clientAppUsed -in $legacyProtocols -and $_.status.status -eq 'Success'
} | Select-Object `
    userDisplayName,
    userPrincipalName,
    clientAppUsed,
    ipAddress,
    createdDateTime,
    @{Name='City';Expression={ $_.location.city }},
    @{Name='Country';Expression={ $_.location.countryOrRegion }},
    deviceDetail |
Sort-Object createdDateTime -Descending |
Format-Table -AutoSize
