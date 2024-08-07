# Microsoft Cloud Logs 

## A primary and security logs for Entra ID, Microsoft 365 and Azure

### Microsoft 365 

* Unified Audit Logs - Enabled by default with 90 or 365 days retention (depending on license). The log contain logs of user and admin activity in Microsoft 365. The log is used to track user and admin activity in Microsoft 365. The log is stored in the Microsoft 365 tenant and can be accessed through the Microsoft 365 Security & Compliance Center. 

### Entra ID (Azure AD)

* Tenant logs (Sign-In & Audit Logs) - Enabled by default with 30 days retention. The log contain Sign-in Logs consisting of Sign-in history and activity and Audit Logs consisting of active directory changes. The log is used to track user sign-in activity and changes to the directory. The log is stored in the Azure AD tenant and can be accessed through the Azure portal or the Microsoft Graph API. 

- Subscription logs - Also called Azure Activity logs. The log enabled by default with 90 days retention. The log Contain logs that detail operations on each Azure service at the management plane. The log contain logs that detail operations on each Azure service at the management plane. These logs are used to determine the who, what, and when for any write operations with a single activity log for each Azure subscription.

### Azure Resource Manager (Azure)

* Resource logs (Diagnostic) - This logs contain logs about operations on each Azure service at the data plane level. These logs are used to track events such as database requests or key vault access attempts. The content of resource logs varies by service and resource type. Resource logs are stored in a storage account or Log Analytics workspace. The retention period for resource logs is configurable and can be set between 30 and 730 days. The Resource Logs can be configured for any Azure services. It can be configured for any Azure services. The content of resource logs varies by service and resource type. 
     
* Azure Virtual machines and services - Captures system data and logging data on the virtual machines and transfers that data into a storage account of your choice. 

* Azure Storage - logging, provides metrics data for a storage account. Provides insight into trace requests, analyzes usage trends, and diagnoses issues with your storage account. 

* NSG flow logs - Contains information about ingress and egress IP traffic through a Network Security Group.
Log type is JSON format, shows outbound and inbound flows on a per-rule basis.

* Azure Kubernetes Service - This log contains the Activity Logs and platform metrics. The Control plane logs for AKS clusters are implemented as resource logs. Resource logs aren’t collected and stored until you create a diagnostic setting. 

* Azure Cosmo DB - Diagnostic settings can be used to log events from the following fields: CollectionName, DatabaseName, OperationType, Region, StatusCode. Logs are not collected and stored by default and should be via diagnostic setting. 

### Defender XDR

* Defender for Cloud Apps – 180 days of data is available here and this length of retention can be critical in an investigation. Data enrichment for IP addresses and other data points is also incredibly useful and the portal makes it very easy to pivot from one data point to another.

* Advanced Hunting – Advanced hunting follows the maximum data retention period configured for the Defender XDR tables. If you stream Defender XDR tables to Microsoft Sentinel and have a data retention period longer than 30 days for said tables, you can query for the longer period in advanced hunting.

#### A general architecture of Forensic artifacts in Microsoft 365 and Entra ID (The image is from the Microsoft techcommunity blog)
![alt text](image.png)