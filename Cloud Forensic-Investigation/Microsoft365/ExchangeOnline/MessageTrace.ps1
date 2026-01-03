# Get Message Trace for Multiple InternetMessageId values 
# Path to the text file containing the InternetMessageId values
$messageIdFile = "C:\temp\messageIds.txt"

# Read all InternetMessageId values from the file
$internetMessageIds = Get-Content -Path $messageIdFile

# Loop through each InternetMessageId and get the message trace
foreach ($id in $internetMessageIds) {
    $traceResult = Get-MessageTrace -InternetMessageId $id

    # Display or process the trace result as needed
    $traceResult | Format-Table
    # Alternatively, you can export results to a file
    $traceResult | Export-Csv -Path "C:\temp\trace_$id.csv" -NoTypeInformation
}