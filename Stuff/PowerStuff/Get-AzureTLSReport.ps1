<#
.SYNOPSIS
    Generates a report for Azure services indicating their configured TLS versions.

.DESCRIPTION
    This script connects to your Azure account and analyzes the TLS version configurations for multiple Azure services.
    It generates a report in CSV and HTML format highlighting any services using insecure TLS versions.
    
    Supported Azure Services:
    - Azure App Service
    - Azure Storage Accounts
    - Azure SQL Database
    - Azure Key Vault
    - Azure Application Gateway
    - Azure Front Door
    - Azure API Management
    - Azure Load Balancer
    - Azure Virtual Network Gateway
    - Azure SignalR Service
    - Azure Redis Cache
    - Azure Service Bus
    - Azure Kubernetes Service

.EXAMPLE
    .\Get-AzureTLSReport.ps1

    This command will generate the Azure TLS Version Report, producing CSV and HTML reports.

.AUTHOR
    Elli Shlomo
#>

# Install required Azure module
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Connect to Azure account
Connect-AzAccount

# Function to generate an advanced report for Azure services using TLS versions
function Get-AzureTLSReport {
    [CmdletBinding()]
    param (
        [string]$ReportPathCSV = "AzureTLSReport.csv",
        [string]$ReportPathHTML = "AzureTLSReport.html"
    )

    $tlsReport = @()

    # Azure App Service
    Get-AzWebApp | ForEach-Object {
        $webApp = $_
        if ($webApp.ResourceGroupName -and $webApp.Name) {
            $appSettings = Get-AzWebApp -ResourceGroupName $webApp.ResourceGroupName -Name $webApp.Name
            if ($appSettings -and ($appSettings.MinimumTlsVersion -in @("1.0", "1", "1.1", "1.2", "1.3"))) {
                $tlsReport += [PSCustomObject]@{
                    ServiceName      = "Azure App Service"
                    ResourceName     = $webApp.Name
                    ResourceGroup    = $webApp.ResourceGroupName
                    TlsVersion       = $appSettings.MinimumTlsVersion
                    Location         = $webApp.Location
                    DefaultHostName  = $webApp.DefaultHostName
                    Sku              = $webApp.Sku.Tier
                    State            = $webApp.State
                    Owner            = ($webApp.Tags["Owner"] -ne $null) ? $webApp.Tags["Owner"] : "N/A"
                    Tags             = ($webApp.Tags | ConvertTo-Json -Compress)
                }
            }
        }
    }

    # Azure Storage Accounts
    Get-AzStorageAccount | ForEach-Object {
        $storageAccount = $_
        if ($storageAccount.ResourceGroupName -and $storageAccount.StorageAccountName) {
            if ($storageAccount.MinimumTlsVersion -in @("TLS1_0", "TLS1_1", "TLS1_2", "TLS1_3")) {
                $tlsReport += [PSCustomObject]@{
                    ServiceName      = "Azure Storage Account"
                    ResourceName     = $storageAccount.StorageAccountName
                    ResourceGroup    = $storageAccount.ResourceGroupName
                    TlsVersion       = $storageAccount.MinimumTlsVersion
                    Location         = $storageAccount.Location
                    Kind             = $storageAccount.Kind
                    Sku              = $storageAccount.Sku.Name
                    EnableHttpsTrafficOnly = $storageAccount.EnableHttpsTrafficOnly
                    Owner            = ($storageAccount.Tags["Owner"] -ne $null) ? $storageAccount.Tags["Owner"] : "N/A"
                    Tags             = ($storageAccount.Tags | ConvertTo-Json -Compress)
                }
            }
        }
    }

    # Azure SQL Database
    Get-AzSqlServer | ForEach-Object {
        $sqlServer = $_
        if ($sqlServer.ResourceGroupName -and $sqlServer.ServerName) {
            if ($sqlServer.MinimalTlsVersion -in @("1.0", "1", "1.1", "1.2", "1.3")) {
                $tlsReport += [PSCustomObject]@{
                    ServiceName      = "Azure SQL Database"
                    ResourceName     = $sqlServer.ServerName
                    ResourceGroup    = $sqlServer.ResourceGroupName
                    TlsVersion       = $sqlServer.MinimalTlsVersion
                    Location         = $sqlServer.Location
                    FullyQualifiedDomainName = $sqlServer.FullyQualifiedDomainName
                    AdministratorLogin = $sqlServer.AdministratorLogin
                    Owner            = ($sqlServer.Tags["Owner"] -ne $null) ? $sqlServer.Tags["Owner"] : "N/A"
                    Tags             = ($sqlServer.Tags | ConvertTo-Json -Compress)
                }
            }
        }
    }

    # Azure Key Vault
    Get-AzKeyVault | ForEach-Object {
        $keyVault = $_
        if ($keyVault.ResourceGroupName -and $keyVault.VaultName) {
            if ($keyVault.Properties.MinimumTlsVersion -in @("1.0", "1", "1.1", "1.2", "1.3")) {
                $tlsReport += [PSCustomObject]@{
                    ServiceName      = "Azure Key Vault"
                    ResourceName     = $keyVault.VaultName
                    ResourceGroup    = $keyVault.ResourceGroupName
                    TlsVersion       = $keyVault.Properties.MinimumTlsVersion
                    Location         = $keyVault.Location
                    EnabledForDeployment = $keyVault.Properties.EnabledForDeployment
                    EnabledForDiskEncryption = $keyVault.Properties.EnabledForDiskEncryption
                    EnabledForTemplateDeployment = $keyVault.Properties.EnabledForTemplateDeployment
                    Owner            = ($keyVault.Tags["Owner"] -ne $null) ? $keyVault.Tags["Owner"] : "N/A"
                    Tags             = ($keyVault.Tags | ConvertTo-Json -Compress)
                }
            }
        }
    }

    # Azure Application Gateway
    Get-AzApplicationGateway | ForEach-Object {
        $appGateway = $_
        if ($appGateway.SslPolicy -and $appGateway.SslPolicy.MinProtocol -in @("TLSv1_0", "TLSv1_1", "TLSv1_2", "TLSv1_3")) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure Application Gateway"
                ResourceName     = $appGateway.Name
                ResourceGroup    = $appGateway.ResourceGroupName
                TlsVersion       = $appGateway.SslPolicy.MinProtocol
                Location         = $appGateway.Location
                Sku              = $appGateway.Sku.Name
                OperationalState = $appGateway.OperationalState
                Tags             = ($appGateway.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure Front Door
    Get-AzFrontDoor | ForEach-Object {
        $frontDoor = $_
        if ($frontDoor.MinimumTlsVersion -in @("1.0", "1.1", "1.2", "1.3")) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure Front Door"
                ResourceName     = $frontDoor.Name
                ResourceGroup    = $frontDoor.ResourceGroupName
                TlsVersion       = $frontDoor.MinimumTlsVersion
                Location         = $frontDoor.Location
                EnabledState     = $frontDoor.EnabledState
                Tags             = ($frontDoor.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure API Management
    Get-AzApiManagement | ForEach-Object {
        $apiManagement = $_
        if ($apiManagement.ResourceGroupName -and $apiManagement.Name -and $apiManagement.Security.MinTlsVersion -in @("1.0", "1.1", "1.2", "1.3")) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure API Management"
                ResourceName     = $apiManagement.Name
                ResourceGroup    = $apiManagement.ResourceGroupName
                TlsVersion       = $apiManagement.Security.MinTlsVersion
                Location         = $apiManagement.Location
                Tags             = ($apiManagement.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure Load Balancer
    Get-AzLoadBalancer | ForEach-Object {
        $loadBalancer = $_
        $tlsReport += [PSCustomObject]@{
            ServiceName      = "Azure Load Balancer"
            ResourceName     = $loadBalancer.Name
            ResourceGroup    = $loadBalancer.ResourceGroupName
            TlsVersion       = "N/A" # Load Balancer doesn't have TLS configuration directly, included for completeness
            Location         = $loadBalancer.Location
            Tags             = ($loadBalancer.Tags | ConvertTo-Json -Compress)
        }
    }

    # Azure Virtual Network Gateway
    Get-AzVirtualNetworkGateway | ForEach-Object {
        $vnetGateway = $_
        $tlsReport += [PSCustomObject]@{
            ServiceName      = "Azure Virtual Network Gateway"
            ResourceName     = $vnetGateway.Name
            ResourceGroup    = $vnetGateway.ResourceGroupName
            TlsVersion       = "N/A" # TLS version not directly applicable, added for report consistency
            Location         = $vnetGateway.Location
            Tags             = ($vnetGateway.Tags | ConvertTo-Json -Compress)
        }
    }

    # Azure SignalR Service
    Get-AzSignalR | ForEach-Object {
        $signalR = $_
        if ($signalR.ResourceGroupName -and $signalR.Name) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure SignalR Service"
                ResourceName     = $signalR.Name
                ResourceGroup    = $signalR.ResourceGroupName
                TlsVersion       = $signalR.TlsVersion
                Location         = $signalR.Location
                Tags             = ($signalR.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure Redis Cache
    Get-AzRedisCache | ForEach-Object {
        $redisCache = $_
        if ($redisCache.MinimumTlsVersion -in @("1.0", "1.1", "1.2", "1.3")) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure Redis Cache"
                ResourceName     = $redisCache.Name
                ResourceGroup    = $redisCache.ResourceGroupName
                TlsVersion       = $redisCache.MinimumTlsVersion
                Location         = $redisCache.Location
                Sku              = $redisCache.Sku.Name
                Tags             = ($redisCache.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure Service Bus
    Get-AzServiceBusNamespace | ForEach-Object {
        $serviceBus = $_
        if ($serviceBus.MinimumTlsVersion -in @("1.0", "1.1", "1.2", "1.3")) {
            $tlsReport += [PSCustomObject]@{
                ServiceName      = "Azure Service Bus"
                ResourceName     = $serviceBus.Name
                ResourceGroup    = $serviceBus.ResourceGroupName
                TlsVersion       = $serviceBus.MinimumTlsVersion
                Location         = $serviceBus.Location
                Tags             = ($serviceBus.Tags | ConvertTo-Json -Compress)
            }
        }
    }

    # Azure Kubernetes Service
    Get-AzAksCluster | ForEach-Object {
        $aksCluster = $_
        $tlsReport += [PSCustomObject]@{
            ServiceName      = "Azure Kubernetes Service"
            ResourceName     = $aksCluster.Name
            ResourceGroup    = $aksCluster.ResourceGroupName
            TlsVersion       = "N/A" # TLS managed internally by Kubernetes
            Location         = $aksCluster.Location
            Tags             = ($aksCluster.Tags | ConvertTo-Json -Compress)
        }
    }

    # Output the report to a CSV file
    $tlsReport | Export-Csv -Path $ReportPathCSV -NoTypeInformation

    # Output the report to an HTML file with color coding for TLS versions
    $htmlContent = @"
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .tls1-0, .tls1-1, .tls1_1 {
            background-color: red;
            color: white;
        }
        .tls1-2, .tls1-3 {
            background-color: green;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Azure TLS Version Report</h1>
    <p>This report provides an overview of TLS configurations for various Azure services. TLS versions 1.0, 1, 1.1, TLS1_0, and TLS1_1 are marked in red, indicating potential security risks, while TLS versions 1.2 and above are marked in green, indicating compliance with current security best practices.</p>
    <table>
        <tr>
            <th>Service Name</th>
            <th>Resource Name</th>
            <th>Resource Group</th>
            <th>TLS Version</th>
            <th>Location</th>
            <th>Owner</th>
            <th>Tags</th>
            <th>Additional Info</th>
        </tr>
"@

    foreach ($entry in $tlsReport) {
        $class = ""
        switch ($entry.TlsVersion) {
            "1.0" { $class = "tls1-0" }
            "1" { $class = "tls1-0" }
            "1.1" { $class = "tls1-1" }
            "TLS1_0" { $class = "tls1-0" }
            "TLS1_1" { $class = "tls1-1" }
            "1.2" { $class = "tls1-2" }
            "1.3" { $class = "tls1-3" }
            default { $class = "" }
        }

        $htmlContent += "<tr class='$class'>"
        $htmlContent += "<td>$($entry.ServiceName)</td>"
        $htmlContent += "<td>$($entry.ResourceName)</td>"
        $htmlContent += "<td>$($entry.ResourceGroup)</td>"
        $htmlContent += "<td>$($entry.TlsVersion)</td>"
        $htmlContent += "<td>$($entry.Location)</td>"
        $htmlContent += "<td>$($entry.Owner)</td>"
        $htmlContent += "<td>$($entry.Tags)</td>"
        $htmlContent += "<td>$($entry | Select-Object -Property * -ExcludeProperty ServiceName, ResourceName, ResourceGroup, TlsVersion, Location, Owner, Tags | ConvertTo-Json -Compress)</td>"
        $htmlContent += "</tr>"
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    # Write HTML content to file
    $htmlContent | Out-File -FilePath $ReportPathHTML

    # Return the report
    return $tlsReport
}

# Run the function to generate the report
$report = Get-AzureTLSReport -ReportPathCSV "AzureTLSReport.csv" -ReportPathHTML "AzureTLSReport.html"
Write-Output "Report generated: AzureTLSReport.csv and AzureTLSReport.html"
