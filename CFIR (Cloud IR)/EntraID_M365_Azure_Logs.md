# Microsoft Cloud Logs 
## A primary logs for Entra ID, Microsoft 365 and Azure

### Microsoft 365 
Unified Audit Logs - Enabled by default with 90 days retention. The log contain logs of user and admin activity in Microsoft 365. The log is used to track user and admin activity in Microsoft 365. The log is stored in the Microsoft 365 tenant and can be accessed through the Microsoft 365 Security & Compliance Center. 

### Entra ID (Azure AD)

Tenant logs (Sign-In & Audit Logs) - Enabled by default with 30 days retention. The log contain Sign-in Logs consisting of Sign-in history and activity and Audit Logs consisting of active directory changes. The log is used to track user sign-in activity and changes to the directory. The log is stored in the Azure AD tenant and can be accessed through the Azure portal or the Microsoft Graph API. 

Subscription logs - Also called Azure Activity logs. The log enabled by default with 90 days retention. The log Contain logs that detail operations on each Azure service at the management plane. The log contain logs that detail operations on each Azure service at the management plane. These logs are used to determine the who, what, and when for any write operations with a single activity log for each Azure subscription.

### Azure Resource Manager (Azure)

Resource logs (Diagnostic) - This logs contain logs about operations on each Azure service at the data plane level. These logs are used to track events such as database requests or key vault access attempts. The content of resource logs varies by service and resource type. Resource logs are stored in a storage account or Log Analytics workspace. The retention period for resource logs is configurable and can be set between 30 and 730 days.

The Resource Logs can be configured for any Azure services. It can be configured for any Azure services. The content of resource logs varies by service and resource type. 
     
Azure Virtual machines and services - Captures system data and logging data on the virtual machines and transfers that data into a storage account of your choice. 

Azure Storage - logging, provides metrics data for a storage account. Provides insight into trace requests, analyzes usage trends, and diagnoses issues with your storage account. 

NSG flow logs - Contains information about ingress and egress IP traffic through a Network Security Group.
Log type is JSON format, shows outbound and inbound flows on a per-rule basis.


