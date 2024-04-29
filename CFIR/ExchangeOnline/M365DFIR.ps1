Clone/Download https://github.com/invictus-ir/Microsoft-Extractor-Suite.git

Install-Module -Name Microsoft-Extractor-Suite -Scope CurrentUser -Force

Install-module -name Microsoft.Graph -Force

Install-module -name ExchangeOnlineManagement -Force

Install-module -name Az -Force

Install-Module -Name AzureADPreview -Force

Install-Module Microsoft.Graph.Beta -Force

Import-Module .\Microsoft-Extractor-Suite.psd1

Install-Module -Name Microsoft-Extractor-Suite

cd /Users/ellishlomo/Downloads/MS-Defender-4-xOPS-main/Evidence-Info/

Connect-M365
Connect-AzureAD
Connect-AzureAZ 

Get-UALAll -Output C:\Users\ellishlomo\Downloads\UALAll.json

Get-Mailbox -Identity Yvan.b@datagroupit.com |fl ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward

$mailboxes = Get-Mailbox
foreach ($mailbox in $mailboxes) {get-InboxRule -Mailbox $mailbox.UserPrincipalName | export-csv "/users/ellishlomo/Downloads/mailbox.csv"} 

$mailboxes = Get-Mailbox
foreach ($mailbox in $mailboxes) {get-InboxRule -Mailbox $mailbox.UserPrincipalName | export-csv "/users/ellishlomo/Downloads/mailbox.csv"} 

Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) -ResultSize 5000 -Operations “New-InboxRule”,”Set-InboxRule”,”Enable-InboxRule” | Export-CSV pathtofile.csv –NoTypeInformation -Encoding utf8 | Export-Csv -Path "/users/ellishlomo/Downloads/mail-rule-activities.csv"

"/users/ellishlomo/Downloads/MailboxAuditLog.csv"


Search-MailboxAuditLog -Operation RemoveFolderPermissions -ShowDetails -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) | Export-Csv -Path "/users/ellishlomo/Downloads/RemoveFolderPermissions.csv"


Search-MailboxAuditLog -Identity -LogonTypes Delegate -ShowDetails -StartDate -EndDate | Select-Object Operation, LogonType, LastAccessed, LogonUserDisplayName

Search-MailboxAuditLog -LogonTypes Delegate -ShowDetails -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) | Export-Csv -Path "/users/ellishlomo/Downloads/Delegate.csv"


get-mailbox -resultsize unlimited  |
foreach {
    Write-Verbose "Checking $($_.alias)..." -Verbose
    $inboxrule = get-inboxrule -Mailbox $_.alias  
    if ($inboxrule) {
        foreach($rule in $inboxrule){
        [PSCustomObject]@{
            Mailbox         = $_.alias
            Rulename        = $rule.name
            Rulepriority    = $rule.priority
            Ruledescription = $rule.description
        }
    }
    }
} | 
Export-csv -Path "/users/ellishlomo/Downloads/InboxRules.csv" -NoTypeInformation