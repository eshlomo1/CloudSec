# Description: This script contains the commands to search the Unified Audit Log in Exchange Online.
Get-Mailbox -Identity Yvan.b@datagroupit.com | fl ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward

$mailboxes = Get-Mailbox
foreach ($mailbox in $mailboxes) {get-InboxRule -Mailbox $mailbox.UserPrincipalName | export-csv "/users/ellishlomo/Downloads/mailbox.csv"} 

$mailboxes = Get-Mailbox
foreach ($mailbox in $mailboxes) {get-InboxRule -Mailbox $mailbox.UserPrincipalName | export-csv "/users/ellishlomo/Downloads/mailbox.csv"} 

Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) -ResultSize 5000 -Operations “New-InboxRule”,”Set-InboxRule”,”Enable-InboxRule” | Export-CSV pathtofile.csv –NoTypeInformation -Encoding utf8 | Export-Csv -Path "/users/ellishlomo/Downloads/mail-rule-activities.csv"

Search-MailboxAuditLog -Operation RemoveFolderPermissions -ShowDetails -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) | Export-Csv -Path "/users/ellishlomo/Downloads/RemoveFolderPermissions.csv"

Search-MailboxAuditLog -Identity -LogonTypes Delegate -ShowDetails -StartDate -EndDate | Select-Object Operation, LogonType, LastAccessed, LogonUserDisplayName

Search-MailboxAuditLog -LogonTypes Delegate -ShowDetails -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) | Export-Csv -Path "/users/ellishlomo/Downloads/Delegate.csv"
