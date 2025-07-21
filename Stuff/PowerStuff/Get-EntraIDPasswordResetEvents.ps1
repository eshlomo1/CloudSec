# Get recent password reset events from Entra ID audit logs
Connect-MgGraph -Scopes "AuditLog.Read.All"
$resetEvents = Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Reset user password'" -Top 100

foreach ($resetEvent in $resetEvents) {
    $user = $resetEvent.InitiatedBy.User.UserPrincipalName
    $timestamp = $resetEvent.ActivityDateTime
    Write-Host "Password reset detected for $user at $timestamp"
    # If you have a way to test password reuse (e.g., via honeypot or user report), alert here
}
