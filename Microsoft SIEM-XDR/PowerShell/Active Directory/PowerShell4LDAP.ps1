# PowerShell Commands for LDAP Queries

#Search for all Domain Controllers (Based 8192)
([adsisearcher]'(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))').FindAll()

#Search for all Domain Controllers (Group 516)
([adsisearcher]'(&(objectCategory=computer)(primaryGroupID=516))').FindAll()

#Find all user SPNs
([adsisearcher]'(&(objectCategory=user)(servicePrincipalName=*))').FindAll()

# Search for all accounts that do not require a password 
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))').FindAll()

Search for all objects with AdminSHHolder
([adsisearcher]'(adminCount=1)').FindAll()

Search for user accounts with SPN but not TGT accounts
([adsisearcher]'(&(objectCategory=user)(!(samAccountName=krbtgt)(servicePrincipalName=*)))').FindAll()


# -----------


# Search for all disabled accounts
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))').FindAll()

# Search for all accounts with password never expires
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))').FindAll()

# Search for all accounts that can delegate
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=16777216))').FindAll()

# Search for all accounts that are trusted for delegation
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=524288))').FindAll()

# Search for all accounts that are not required to pre-authenticate
([adsisearcher]'(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))').FindAll()