## Remove guest users who haven't signed in for more than 90 days  
# Get a list of guest users
$guestUsers = Get-EntraUser -Filter "userType eq 'Guest'"

# Current date for comparison
$currentDate = Get-Date

# Filter guest users who haven't signed in for more than 90 days and remove them
$guestUsers | Where-Object {
    # Parse lastSignInDateTime to DateTime object
    $lastSignIn = $_.signInActivity.lastSignInDateTime
    $lastSignInDate = [DateTime]::Parse($lastSignIn)

    # Calculate the difference in days
    $daysDifference = ($currentDate - $lastSignInDate).Days

    # Check if difference is greater than 90 days
    return $daysDifference -gt 90
} | ForEach-Object {
    Remove-EntraUser -ObjectId $_.ObjectId -Force
}