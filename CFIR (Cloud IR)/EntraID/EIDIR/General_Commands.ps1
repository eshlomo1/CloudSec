# Detecting OAuth Consents Granting Offline Access in Entra ID
Get-EntraAuditDirectoryLog -All |
Where-Object { $_.ActivityDisplayName -eq 'Consent to application' -and ($_.AdditionalDetails | Where-Object { $_.Key -eq 'PermissionList' -and $_.Value -like '*offline_access*' }) } |
Select-Object ActivityDateTime, @{Name='User';Expression={$_.InitiatedByUser.UserPrincipalName}}, TargetResources

# ------------------------------------------------------------------------------------------

# Detect Client Secrets Expiring Soon (within 30 days)
Get-MgApplication -All | ForEach-Object {
  $_.PasswordCredentials | Where-Object { $_.EndDateTime -le (Get-Date).AddDays(30) } | ForEach-Object {
    [PSCustomObject]@{
      AppDisplayName = $_.DisplayName
      SecretEndDate  = $_.EndDateTime
      AppId         = $_.AppId
    }
  }
}

# ------------------------------------------------------------------------------------------

# List All Client Secrets with Expiry Dates
Get-MgApplication -All | ForEach-Object {
  $_.PasswordCredentials | ForEach-Object {
    [PSCustomObject]@{
      AppDisplayName = $_.DisplayName
      SecretStartDate = $_.StartDateTime
      SecretEndDate = $_.EndDateTime
      AppId = $_.AppId
    }
  }
}

# ------------------------------------------------------------------------------------------

# List Applications with Certificate Credentials and Their Expiry Dates
Get-MgApplication -All | ForEach-Object {
  $_.KeyCredentials | ForEach-Object {
    [PSCustomObject]@{
      AppDisplayName = $_.DisplayName
      CertificateStartDate = $_.StartDateTime
      CertificateEndDate = $_.EndDateTime
      AppId = $_.AppId
      KeyId = $_.KeyId
    }
  }
}

# ------------------------------------------------------------------------------------------

# Detect Entra ID application registrations that have redirect URIs configured (Based OAuth flows)
Get-MgApplication -All | Where-Object { 
    ($_.Web.RedirectUris.Count -gt 0) -or 
    ($_.Spa.RedirectUris.Count -gt 0) -or
    ($_.PublicClient.RedirectUris.Count -gt 0)
} | Select-Object DisplayName, AppId, 
    @{Name='RedirectUris';Expression={
        ($_.Web.RedirectUris + $_.Spa.RedirectUris + $_.PublicClient.RedirectUris) -join '; '
    }} | Format-Table -AutoSize

# ------------------------------------------------------------------------------------------

# List non-human objects like service principals and managed identities
Get-EntraServicePrincipal -All | Select-Object DisplayName, AppId, ServicePrincipalType | Format-Table -AutoSize




