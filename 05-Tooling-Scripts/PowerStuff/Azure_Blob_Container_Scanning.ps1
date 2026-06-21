### Elli Shlomo
# Generate a list of dynamic storage account names based on common patterns
function Generate-ThousandsOfDynamicStorageNames {
    $prefixes = @("storage", "blob", "cloud", "sql", "snowfl", "data", "archive")  # Common prefixes for storage names
    $suffixes = @("01", "02", "backup", "dev", "prod")  # Common suffixes
    $dynamicNames = @()
    
    # Use numeric and alphabetic combinations to generate a large number of names
    for ($i = 0; $i -lt 100; $i++) {  # Outer loop to increase scale
        $number = "{0:D3}" -f $i  # Format numbers to have leading zeros (e.g., 001, 002)
        
        foreach ($prefix in $prefixes) {
            foreach ($suffix in $suffixes) {
                # Combine prefix, number, and suffix to form a unique storage name
                $dynamicNames += "$prefix$number$suffix"
            }
        }
    }

    return $dynamicNames
}

# Azure Blob Storage endpoint suffix
$azureBlobSuffix = ".blob.core.windows.net"

# Function to check if a storage account has publicly accessible blob containers
function Get-PublicBlobContainersByStorageName {
    param (
        [string]$storageAccountName,
        [ref]$results
    )

    # Build the storage account URL
    $storageAccountUrl = "https://${storageAccountName}${azureBlobSuffix}"

    # Build the request URL for listing containers
    $requestUrl = "${storageAccountUrl}/?comp=list"

    try {
        # Send an unauthenticated GET request to the storage account endpoint
        $response = Invoke-RestMethod -Uri $requestUrl -Method Get

        if ($response.Containers.Container.Count -gt 0) {
            Write-Host "Publicly accessible blob containers found at ${storageAccountUrl}:"
            foreach ($container in $response.Containers.Container) {
                Write-Host " - " $container.Name
                # Add the result to the results array
                $results.Value += @{
                    StorageAccount = $storageAccountName;
                    Container = $container.Name;
                    Url = "$storageAccountUrl/$container.Name"
                }
            }
        } else {
            Write-Host "No publicly accessible containers found at ${storageAccountUrl}."
        }
    }
    catch {
        Write-Host "Failed to access ${storageAccountUrl}. It may not be publicly accessible or doesn't exist."
    }
}

# Function to export the results to an HTML file
function Export-ResultsToHTML {
    param (
        [array]$results,
        [string]$filePath
    )

    # Create the basic HTML structure
    $htmlContent = @"
<html>
<head>
    <title>Public Azure Blob Containers Report</title>
</head>
<body>
    <h1>Public Azure Blob Containers</h1>
    <table border="1">
        <tr>
            <th>Storage Account</th>
            <th>Container Name</th>
            <th>URL</th>
        </tr>
"@

    # Append each result as a table row
    foreach ($result in $results) {
        $htmlContent += "<tr><td>$($result.StorageAccount)</td><td>$($result.Container)</td><td><a href='$($result.Url)'>$($result.Url)</a></td></tr>`n"
    }

    # Close the HTML structure
    $htmlContent += @"
    </table>
</body>
</html>
"@

    # Write the HTML content to the specified file
    $htmlContent | Out-File -FilePath $filePath
    Write-Host "Results exported to $filePath"
}

# Generate thousands of dynamic storage account names
$dynamicStorageNames = Generate-ThousandsOfDynamicStorageNames

# Initialize an empty array to store results
$results = @()

# Iterate through the dynamic storage names and check each one
foreach ($storageName in $dynamicStorageNames) {
    Get-PublicBlobContainersByStorageName -storageAccountName $storageName -results ([ref]$results)
}

# If any results were found, export them to an HTML file
if ($results.Count -gt 0) {
    Export-ResultsToHTML -results $results -filePath "PublicBlobContainersReport.html"
} else {
    Write-Host "No publicly accessible blob containers found."
}
