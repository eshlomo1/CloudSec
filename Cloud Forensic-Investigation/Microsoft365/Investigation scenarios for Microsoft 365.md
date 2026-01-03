# Investigation scenarios for Microsoft 365 

## Search for activities related to the attacker's actions  

* New admin role assignments – To verify new privileged admin roles are assigned to users, applications, service principals, etc.  
* MailItemsAccessed – Accessed mailbox items to determine if the attackers accessed sensitive emails.  
* Consent to application - search for any sensitive permissions have been newly granted to an application to access the resources on behalf of a user.   
* Application modification - search for a new credentials have been added to an existing application or a service principal.  
* Directory role changes – To verify the recent changes made in the directory role and role group memberships. 
* HardDelete and Purging messages from mailboxes – Search for a confidential messages were permanently deleted from the mailbox.  
* Inbox rule (New-InboxRule) - Search for any forwarding or redirecting rules have been created for the admin mailboxes. Inlcuding hidden mailbox rule. 
* SharePoint and OneDrive File Activities — search for file accesses, file deletions, etc., will be monitored to identify if any sensitive files have been accessed and used.  
* Role group member changes (Update-RoleGroupMember) – search for new members were added to highly privileged role groups like Organization Management.  
* eDiscovery role additions —  search for user assigned or removed from an eDiscovery role like ‘eDiscovery Manager’ or ‘eDiscovery Administrator.’  
* eDiscovery compliance search and exports –  search for any eDiscovery searches or content search results have been exported by the attackers.  
