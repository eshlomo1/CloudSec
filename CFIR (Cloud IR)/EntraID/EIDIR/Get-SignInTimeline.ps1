<#
.SYNOPSIS
    Generates a comprehensive timeline of Entra ID (Azure AD) sign-in activities.

.DESCRIPTION
    This script retrieves and analyzes Microsoft Entra ID (Azure AD) sign-in logs to create 
    a detailed timeline of authentication activities. It provides a comprehensive view of 
    sign-in patterns across your organization with essential details like location, device, 
    risk levels, and authentication methods.

    The script retrieves specific fields for each sign-in:
    - Time of sign-in
    - User Principal Name
    - Sign-in Status (Success/Failure)
    - Geographic Location (City, Country)
    - IP Address
    - Application Accessed
    - Device Operating System
    - Browser Information
    - Risk Level Assessment
    - Authentication Methods Used

    Results can be displayed in the console and optionally exported to a CSV file 
    with a timestamp for further analysis or record-keeping.

.PARAMETER None
    This script does not accept parameters. Modify the script directly to customize:
    - CSV export path
    - Fields displayed
    - Sorting options

.EXAMPLE
    .\Get-SignInTimeline.ps1
    Retrieves all sign-in logs and displays them in a formatted table

.NOTES
    Script Name    : Get-SignInTimeline.ps1
    Version       : 1.0
    Author        : Elli Shlomo
    Purpose       : Part of the EntraID Security Monitoring Scripts Collection
    
    Prerequisites:
    - Microsoft.Entra PowerShell module
    - Appropriate permissions to read sign-in logs
    - Global Reader, Security Reader, or Reports Reader role (minimum)


.COMPONENT
    Microsoft Entra ID, Identity Protection

#>

# ========================================
# SCRIPT CONFIGURATION AND EXECUTION
# ========================================

# Retrieve all sign-ins (success/failure) with key fields for timeline analysis
# Optionally, save results to CSV

# Get sign-in logs with 10 important fields
$allSignIns = Get-EntraAuditSignInLog -All | Select-Object `
    @{Name='Time';Expression={$_.CreatedDateTime}}, `
    @{Name='User';Expression={$_.UserPrincipalName}}, `
    @{Name='Status';Expression={$_.Status.ErrorCode -eq 0 ? 'Success' : 'Failure'}}, `
    @{Name='Location';Expression={$_.Location.City + ', ' + $_.Location.CountryOrRegion}}, `
    @{Name='IP Address';Expression={$_.IpAddress}}, `
    @{Name='App';Expression={$_.AppDisplayName}}, `
    @{Name='Device OS';Expression={$_.DeviceDetail.OperatingSystem}}, `
    @{Name='Browser';Expression={$_.DeviceDetail.Browser}}, `
    @{Name='Risk Level';Expression={$_.RiskLevelAggregated}}, `
    @{Name='Auth Method';Expression={$_.AuthenticationDetails.AuthenticationMethod -join ', '}}

# Display results in formatted table
$allSignIns | Sort-Object Time -Descending | Format-Table -AutoSize

# Save to CSV with timestamp (uncomment the next line to enable)
# $allSignIns | Export-Csv -Path "SignInLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation -Encoding UTF8
