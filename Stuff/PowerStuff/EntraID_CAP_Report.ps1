<#
.SYNOPSIS
    Generates an Entra ID Conditional Access Analysis Report in HTML format.

.DESCRIPTION
    This script connects to Microsoft Graph to retrieve Entra ID Conditional Access sign-in data for analysis.
    It generates a detailed HTML report with metrics such as total sign-ins, protected and unprotected sign-ins, 
    failed logins, password-only authentications, unique resources accessed, and access locations.
    The report includes a comparison with the previous month and is saved to the Documents folder.

.PARAMETER ReportPath
    Specifies the file path for the generated HTML report. The default location is the Documents folder.

.EXAMPLE
    PS> .\Generate-EntraIDConditionalAccessReport.ps1
    Generates a report and saves it in the Documents folder with a default name.

.NOTES
    Author: Elli Shlomo
    This script requires the Microsoft.Graph module and appropriate permissions to access Entra ID data.
    This script runs on PowerShell wtih Macos only.

#>

# Install Microsoft Graph Module if not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Import the Microsoft Graph Module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph with required permissions
try {
    Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.Read.All", "Directory.Read.All"
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Please check your permissions and network connectivity."
    exit
}

# Initialize metrics
$totalSignIns = 0
$protectedSignIns = 0
$unprotectedSignIns = 0
$failedLogins = 0
$passwordOnlySignIns = 0
$uniqueResources = 0
$accessLocations = 0
$totalSignInsLastMonth = 0

try {
    # Define date ranges
    $startDateThisMonth = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $startDateLastMonth = (Get-Date).AddMonths(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $endDateLastMonth = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Retrieve sign-ins from the last 7 days
    $signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDateThisMonth" -All
    $totalSignIns = $signIns.Count
    $protectedSignIns = ($signIns | Where-Object { $_.conditionalAccessPolicies -ne $null }).Count
    $unprotectedSignIns = $totalSignIns - $protectedSignIns
    $failedLogins = ($signIns | Where-Object { $_.status.errorCode -ne 0 }).Count
    $passwordOnlySignIns = ($signIns | Where-Object { $_.authenticationMethodsUsed -eq "password" }).Count
    $uniqueResources = ($signIns | Select-Object -ExpandProperty resourceDisplayName -Unique).Count
    $accessLocations = ($signIns | Select-Object -ExpandProperty location -Unique).Count

    # Retrieve sign-ins from the previous month for comparison
    $signInsLastMonth = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDateLastMonth and createdDateTime lt $endDateLastMonth" -All
    $totalSignInsLastMonth = $signInsLastMonth.Count

} catch {
    Write-Host "Error retrieving sign-in data: $_"
    exit
}

# Set the date and time the report is generated
$reportGenerated = (Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

# Define HTML report path for macOS
$htmlPath = "$HOME/Documents/EntraIDConditionalAccessAnalysisReport.html"

# Start building HTML content with enhanced styling
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Entra ID Conditional Access Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f9f9f9; color: #333; }
        .container { width: 100%; max-width: 1200px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; background-color: #fff; }
        .header { text-align: center; padding: 20px 0; background-color: #2F4F4F; color: #fff; }
        .header h1 { font-size: 28px; font-weight: bold; margin: 0; }
        .summary-section { display: flex; flex-wrap: wrap; justify-content: space-between; padding: 20px 0; }
        .summary-item { width: 30%; background-color: #e0e0e0; margin: 10px 0; padding: 15px; border-radius: 8px; text-align: center; }
        .summary-item h3 { font-size: 18px; font-weight: bold; color: #333; margin: 0; }
        .summary-item p { font-size: 22px; font-weight: bold; color: #333; margin: 10px 0 0; }
        .section-title { font-size: 24px; font-weight: bold; color: #2F4F4F; margin-top: 40px; }
        .comparison-table { width: 100%; margin-top: 20px; border-collapse: collapse; }
        .comparison-table th, .comparison-table td { padding: 10px; border: 1px solid #ccc; text-align: center; }
        .policy-details { margin-top: 30px; }
        .policy-item { margin-bottom: 20px; padding: 15px; border: 1px solid #ccc; border-radius: 8px; background-color: #fafafa; }
        .policy-item h4 { font-size: 18px; color: #333; margin: 0 0 5px; }
        .policy-item p { font-size: 14px; color: #555; margin: 0; }
        .footer { text-align: center; padding: 10px; margin-top: 30px; font-size: 14px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Entra ID Conditional Access Analysis Report</h1>
        </div>
        
        <!-- Summary Section -->
        <div class="summary-section">
            <div class="summary-item">
                <h3>Report Generated</h3>
                <p>$reportGenerated</p>
            </div>
            <div class="summary-item">
                <h3>Time Range</h3>
                <p>7 days</p>
            </div>
            <div class="summary-item">
                <h3>Total Sign-ins</h3>
                <p>$totalSignIns</p>
                <div class="small-text">Last Month: $totalSignInsLastMonth</div>
            </div>
            <div class="summary-item">
                <h3>Protected Sign-ins</h3>
                <p>$protectedSignIns</p>
            </div>
            <div class="summary-item">
                <h3>Unprotected Sign-ins</h3>
                <p>$unprotectedSignIns</p>
            </div>
            <div class="summary-item">
                <h3>Failed Logins</h3>
                <p>$failedLogins</p>
            </div>
            <div class="summary-item">
                <h3>Password-Only Authentications</h3>
                <p>$passwordOnlySignIns</p>
            </div>
            <div class="summary-item">
                <h3>Unique Resources Accessed</h3>
                <p>$uniqueResources</p>
            </div>
            <div class="summary-item">
                <h3>Access Locations</h3>
                <p>$accessLocations</p>
            </div>
        </div>

        <!-- Monthly Comparison Table -->
        <h2 class="section-title">Monthly Comparison</h2>
        <table class="comparison-table">
            <tr>
                <th>Metric</th>
                <th>This Month</th>
                <th>Last Month</th>
            </tr>
            <tr>
                <td>Total Sign-ins</td>
                <td>$totalSignIns</td>
                <td>$totalSignInsLastMonth</td>
            </tr>
            <tr>
                <td>Protected Sign-ins</td>
                <td>$protectedSignIns</td>
                <td>N/A</td>
            </tr>
            <tr>
                <td>Unprotected Sign-ins</td>
                <td>$unprotectedSignIns</td>
                <td>N/A</td>
            </tr>
            <tr>
                <td>Failed Logins</td>
                <td>$failedLogins</td>
                <td>N/A</td>
            </tr>
            <tr>
                <td>Password-Only Authentications</td>
                <td>$passwordOnlySignIns</td>
                <td>N/A</td>
            </tr>
        </table>

        <!-- Footer Section -->
        <div class="footer">
            <p>By Elli Shlomo</p>
        </div>
    </div> <!-- End of Container -->
</body>
</html>
"@

# Write HTML content to file
try {
    Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
    Write-Host "Entra ID Conditional Access Analysis Report generated successfully!"
    Write-Host "HTML Report: $htmlPath"
} catch {
    Write-Host "Failed to write the report to the file. Please check the file path and permissions."
}
