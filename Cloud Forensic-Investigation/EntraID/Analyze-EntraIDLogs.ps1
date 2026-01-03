<#
.SYNOPSIS
    Entra ID Log Correlation and Analysis Tool (InteractiveSignIns)

.DESCRIPTION
    This PowerShell script processes raw CSV exports of Microsoft Entra ID (Azure AD) sign-in and audit logs, normalizing the data, deduplicating headers, and filtering out non-essential fields. It dynamically identifies key fields such as user identifiers, IP addresses, application names, and token/session IDs for correlation and summarization.

    The script generates:
    - An HTML report summarizing total events and unique values per field (user, IP, app, token)
    - A findings table of raw log entries (cleaned and normalized)
    - A cleaned CSV export with removed noisy/unnecessary columns

    This script is designed for use in digital forensics, incident response, threat hunting, and audit reviews across Entra ID activity logs, especially in hybrid or cloud-only identity environments.

.PARAMETER LogFile
    The path to the input CSV file containing raw Entra ID log data.

.PARAMETER OutputHtml
    The path to save the generated HTML summary report.

.PARAMETER OutputCsv
    The path to save the cleaned and processed CSV file.

.EXAMPLE
    .\Analyze-EntraIDLogs.ps1 -LogFile ".\signins.csv" -OutputHtml ".\report.html" -OutputCsv ".\cleaned.csv"

.NOTES
    Author: Elli Shlomo 
    Version: 1.1
    Dependencies: None (pure PowerShell)
    Tested On: Windows PowerShell 5.1 and PowerShell Core 7.4+
#>

param(
    [Parameter(Mandatory)]
    [string]$LogFile,
    [Parameter(Mandatory)]
    [string]$OutputHtml,
    [Parameter(Mandatory)]
    [string]$OutputCsv
)

# --- 1. Preprocess CSV to handle duplicate headers ---
$raw = Get-Content $LogFile
$header = $raw[0] -replace "`r",""
$rows = $raw[1..($raw.Count-1)]

# Make headers unique
$headerParts = $header -split ','
$headerMap = @{}
for ($i=0; $i -lt $headerParts.Count; $i++) {
    $col = $headerParts[$i].Trim('"')
    if ($headerMap.ContainsKey($col)) {
        $headerParts[$i] = "$col`_$($headerMap[$col]+1)"
        $headerMap[$col]++
    } else {
        $headerMap[$col] = 1
    }
}
$fixedHeader = ($headerParts | ForEach-Object { '"{0}"' -f $_ }) -join ','

# Write to temp file
$tmp = [System.IO.Path]::GetTempFileName()
Set-Content $tmp $fixedHeader
Add-Content $tmp $rows

# Import fixed CSV
$log = Import-Csv -Path $tmp

# --- 2. Remove unwanted columns ---
$columns = $log[0].psobject.Properties.Name

$removeFields = @(
    'Associated Resource Id','Federated Token Id','Token Issuer',
    'Device ID','Home tenant name','Token Protection - Sign In Session StatusCode'
)
function ShouldRemove($col) {
    foreach ($r in $removeFields) {
        if ( ($col -replace '\s','').ToLower() -eq ($r -replace '\s','').ToLower() ) { return $true }
    }
    return $false
}
$keepColumns = $columns | Where-Object { -not (ShouldRemove $_) }
$log = $log | Select-Object $keepColumns
$columns = $log[0].psobject.Properties.Name

# --- 3. Improved Summary Section ---
function Get-FirstAvailableColumn {
    param($columns, $candidates)
    foreach ($c in $candidates) {
        $actual = $columns | Where-Object { ($_ -replace '\s','').ToLower() -eq ($c -replace '\s','').ToLower() }
        if ($actual) { return $actual[0] }
    }
    return $null
}
$userCandidates = @('User','Username','User ID','Sign-in identifier')
$ipCandidates = @('IP address','IP','IP address (seen by resource)')
$appCandidates = @('Application','App','Client app')
$tokenCandidates = @('Unique token identifier','Token','Session ID')

$userColSum = Get-FirstAvailableColumn $columns $userCandidates
$ipColSum = Get-FirstAvailableColumn $columns $ipCandidates
$appColSum = Get-FirstAvailableColumn $columns $appCandidates
$tokenColSum = Get-FirstAvailableColumn $columns $tokenCandidates

$total = $log.Count
$uniqueUsers = if ($userColSum) { ($log | Select-Object -ExpandProperty $userColSum -Unique | Where-Object { $_ -and $_ -ne "" }).Count } else { 0 }
$uniqueIPs = if ($ipColSum) { ($log | Select-Object -ExpandProperty $ipColSum -Unique | Where-Object { $_ -and $_ -ne "" }).Count } else { 0 }
$uniqueApps = if ($appColSum) { ($log | Select-Object -ExpandProperty $appColSum -Unique | Where-Object { $_ -and $_ -ne "" }).Count } else { 0 }
$uniqueTokens = if ($tokenColSum) { ($log | Select-Object -ExpandProperty $tokenColSum -Unique | Where-Object { $_ -and $_ -ne "" }).Count } else { 0 }

# --- 4. Evidence/Findings Table ---
function Normalize-Field($value) {
    if ($null -eq $value -or $value -eq "") { return "<none>" }
    return $value
}

# --- 5. HTML Output ---
$html = @"
<html>
<head>
    <title>Entra ID Log Findings and Evidence</title>
    <style>
        body { font-family: Arial; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ccc; padding: 4px; }
        th { background: #eee; }
        .small { font-size: 10px; }
    </style>
</head>
<body>
    <h1>Entra ID Log Correlation Analysis</h1>
    <h2>Summary</h2>
    <ul>
        <li>Total Events: $total</li>
        <li>Unique Users: $uniqueUsers (Column: $userColSum)</li>
        <li>Unique IPs: $uniqueIPs (Column: $ipColSum)</li>
        <li>Unique Applications: $uniqueApps (Column: $appColSum)</li>
        <li>Unique Tokens: $uniqueTokens (Column: $tokenColSum)</li>
    </ul>
    <h2>Findings and Evidence</h2>
    <table class='small'>
        <tr>
"@
foreach ($col in $columns) { $html += "<th>$col</th>" }
$html += "</tr>"
foreach ($row in $log) {
    $html += "<tr>"
    foreach ($col in $columns) {
        $html += "<td>" + (Normalize-Field $row.$col) + "</td>"
    }
    $html += "</tr>"
}
$html += "</table>"

$html += "</body></html>"

$html | Out-File -FilePath $OutputHtml -Encoding utf8

# --- 6. Export to CSV ---
$log | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Analysis complete. HTML: $OutputHtml CSV: $OutputCsv"

# Clean up temp file
Remove-Item $tmp -Force
