# This PowerShell script connects to Exchange Online, retrieves mailbox forwarding rules, and checks for rules that forward emails to external recipients. It outputs these rules to a CSV file.
Function Connect-EXOnline {
     param (
         [Parameter(Mandatory=$true)]
         [pscredential]$Credentials
     )
 
     $Session = New-PSSession -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
         -ConfigurationName Microsoft.Exchange `
         -Credential $Credentials `
         -Authentication Basic -AllowRedirection
     Import-PSSession $Session -ErrorAction Stop
 }
 
 Function Get-ExternalForwardingRules {
     param (
         [Parameter(Mandatory=$true)]
         [array]$Domains,
         [Parameter(Mandatory=$true)]
         [psobject]$Mailbox
     )
 
     $rules = Get-InboxRule -Mailbox $Mailbox.PrimarySmtpAddress -ErrorAction Stop
 
     $forwardingRules = $rules | Where-Object { $_.ForwardTo -or $_.ForwardAsAttachmentTo }
     
     $externalRules = @()
     
     foreach ($rule in $forwardingRules) {
         $recipients = @($rule.ForwardTo + $rule.ForwardAsAttachmentTo) | Where-Object { $_ -match "SMTP" }
         
         $externalRecipients = @()
         foreach ($recipient in $recipients) {
             $email = ($recipient -split "SMTP:")[1].Trim("]")
             $domain = ($email -split "@")[1]
             
             if ($Domains.DomainName -notcontains $domain) {
                 $externalRecipients += $email
             }
         }
 
         if ($externalRecipients) {
             $extRecString = $externalRecipients -join ", "
             
             $ruleHash = [ordered]@{
                 PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
                 DisplayName        = $Mailbox.DisplayName
                 RuleId             = $rule.Identity
                 RuleName           = $rule.Name
                 RuleDescription    = $rule.Description
                 ExternalRecipients = $extRecString
             }
             $externalRules += [PSCustomObject]$ruleHash
         }
     }
 
     return $externalRules
 }
 
 try {
     $credentials = Get-Credential -ErrorAction Stop
     Connect-EXOnline -Credentials $credentials
 
     $domains = Get-AcceptedDomain -ErrorAction Stop
     $mailboxes = Get-Mailbox -ResultSize Unlimited -ErrorAction Stop
 
     $externalRulesCollection = @()
 
     foreach ($mailbox in $mailboxes) {
         $externalRules = Get-ExternalForwardingRules -Domains $domains -Mailbox $mailbox
         $externalRulesCollection += $externalRules
     }
 
     if ($externalRulesCollection) {
         $externalRulesCollection | Export-Csv -Path "/Users/ellishlomo/Documents/EXO_External_Inbox_Rules.csv" -NoTypeInformation -Force
     }
 } catch {
     Write-Error "An error occurred: $_"
 } finally {
     if ($Session) {
         Remove-PSSession $Session
     }
 }
 