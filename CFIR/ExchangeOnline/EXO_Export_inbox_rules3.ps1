# Description: This script will get all the mailbox rules that are forwarding emails to external domains and save the output to a CSV file. 
 
$MailboxList = get-mailbox -ResultSize Unlimited | where{$_.IsMailboxEnabled -eq $True} | Select-Object Name, WindowsEmailAddress
foreach($Mailbox in $MailboxList){
$MailboxAddress = ($Mailbox.WindowsEmailAddress).ToString()

Get-InboxRule -mailbox $MailboxAddress | 
where{($_.ForwardAsAttachmentTo -ne $NULL -and $_.ForwardAsAttachmentTo -notlike "*/ou=*") -or ($_.ForwardTo -notlike "*/ou=*" -and $_.ForwardTo -ne $NULL)} | 
FL MailboxOwnerId, Description, Enabled, ForwardTo, ForwardAsAttachmentTo | 
Out-File -Append /users/ellishlomo/Downloads/MailboxForwardingAuto.csv
}