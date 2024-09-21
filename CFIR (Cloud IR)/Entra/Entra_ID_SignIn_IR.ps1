<#
.SYNOPSIS
# This PowerShell commands demonstrates how to investigate user activity in Entra ID using the Microsoft Graph PowerShell SDK.
# It covers various scenarios such as analyzing sign-in logs, conditional access policies, role assignments, and more.
# The commands provides querying audit logs, filtering data, and exporting results to CSV files.

.NOTES
# File Name      : Entra_ID_IR.ps1
# Author         : Elli Shlomo
# Prerequisite   : Install the Microsoft Graph PowerShell SDK
#                  https://docs.microsoft.com/en-us/powershell/module/microsoft.graph/?view=graph-powershell
# Description    : Investigate user activity in Microsoft 365 using the Microsoft Graph PowerShell SDK.
# Version        : 1.0
#>

# ----- Module Installation and Authentication
## Install the Microsoft Graph PowerShell SDK
Install-Module Microsoft.Graph

## Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All", "Reports.Read.All"

# ----- Sign-In Logs investigation 

# Define Date and UPN parameters
$UPN = "user@domain.com"
$Time = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Search for sign-in logs for a specific user
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN' and createdDateTime ge $Time" |
Select-Object userPrincipalName, appDisplayName, ipAddress, status, createdDateTime 

# Search for Signin logs for a specific user and country code

## Define the country code and time frame (30 days back)
$countryCode = "US"  # Replace with your specific country code (e.g., "US" for the United States)
$Time = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Search sign-in logs for the specific country code and within the last 30 days
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN' and createdDateTime ge $Time and location/countryOrRegion eq '$countryCode'" |
    Select-Object userPrincipalName, appDisplayName, ipAddress, location, status, createdDateTime

# -----  Identify Anomalous IP Addresses

## Group sign-ins by IP and count occurrences, flagging unusual access patterns
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN'" |
    Group-Object ipAddress | 
    Where-Object {$_.Count -gt 5} | 
    Select-Object Name, Count

# ----- Investigate Audit Logs for User Activity

# Search audit logs for the user activity 
Get-MgAuditLogDirectoryAudit -Filter "targetResources/any(t: t/userPrincipalName eq '$UPN')" |
    Select-Object activityDisplayName, targetResources, initiatedBy, activityDateTime

# ----- Investigate Conditional Access Policies (CAPs) 

# Search Conditional Access Policies (CAPs) 
Get-MgIdentityConditionalAccessPolicy |
    Select-Object DisplayName, State, Conditions, GrantControls

Get-MgIdentityConditionalAccessPolicy | ConvertTo-Json | Out-File "ConditionalAccessPolicies.json"

## Recent Changes to Conditional Access Policies 

$auditLogs = Get-MgAuditLogSignIn | Where-Object { $_.Activity -like '*ConditionalAccess*' }
$recentChanges = $auditLogs | Where-Object { $_.ActivityDate -ge (Get-Date).AddDays(-7) }

if ($recentChanges) {
    Write-Host "Recent Conditional Access Policy Changes:"
    $recentChanges | ForEach-Object { Write-Host "Changed by: $($_.InitiatedBy.UserPrincipalName) at $($_.ActivityDate)" }
} else {
    Write-Host "No recent changes to Conditional Access Policies."
}

# ----- Investigate Conditional Access Policies for a Specific User

$userPrincipalName = "user@domain.com"
$policiesForUser = @()

foreach ($policy in $conditionalAccessPolicies) {
    if ($policy.Conditions.Users.IncludeUsers -contains $userPrincipalName -or 
        ($policy.Conditions.Users.IncludeGroups -and $user.ObjectId -in (Get-MgUserMemberOf -UserId $userId))) {
        $policiesForUser += $policy
    }
}

## Output the relevant policies for the specific user
$policiesForUser | ForEach-Object {
    Write-Host "Policy Name: " $_.DisplayName
    Write-Host "Grant Controls: " $_.GrantControls
    Write-Host "Session Controls: " $_.SessionControls
    Write-Host "Conditions: " $_.Conditions
    Write-Host "--------------------------------------"
}

# -------- Analyze Sign-In Logs for Conditional Access Application

$signInLogs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$userPrincipalName'" -All

foreach ($log in $signInLogs) {
    Write-Host "Sign-In Time: " $log.CreatedDateTime
    Write-Host "User: " $log.UserPrincipalName
    Write-Host "Conditional Access Policies Applied: " $log.AppliedConditionalAccessPolicies
    Write-Host "Sign-In Status: " $log.Status
    Write-Host "--------------------------------------"
}

## Investigate Sign-In Failures for a User 

$failedSignInLogs = $signInLogs | Where-Object { $_.Status.ErrorCode -ne 0 }

foreach ($failedLog in $failedSignInLogs) {
    Write-Host "Failed Sign-In Time: " $failedLog.CreatedDateTime
    Write-Host "Conditional Access Policies Applied: " $failedLog.AppliedConditionalAccessPolicies
    Write-Host "Failure Reason: " $failedLog.Status.FailureReason
    Write-Host "--------------------------------------"
}

## Export the results to CSV files

$policiesForUser | Export-Csv -Path "PoliciesForUser.csv" -NoTypeInformation
$signInLogs | Export-Csv -Path "SignInLogsForUser.csv" -NoTypeInformation

# ------- Suspicious MFA Activity 

# Search audit logs for MFA changes (user enabling/disabling MFA)
Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Update MFA Factors'" |
    Select-Object userPrincipalName, activityDisplayName, targetResources, initiatedBy, activityDateTime

## Get a sample of audit logs
$auditLogs = Get-MgAuditLogDirectoryAudit -Top 1000

## Get a distinct list of activity display names
$auditLogs | Select-Object -ExpandProperty activityDisplayName | Sort-Object -Unique

## List All Applications Accessed by the User 

## Get sign-in logs to determine applications accessed by the user
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN'" |
    Select-Object appDisplayName, createdDateTime, ipAddress, status

# Investigate Role Assignments for a User

## Search role assignment changes for a user
Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$UPN'" |
    Select-Object principalId, roleDefinitionId, roleDefinitionDisplayName, principalDisplayName, createdDateTime

## Export sign-in logs to a CSV file
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UPN'" |
    Select-Object userPrincipalName, appDisplayName, ipAddress, status, createdDateTime |
    Export-Csv -Path "C:\Investigations\SignInLogs$($userPrincipalName).csv" -NoTypeInformation
