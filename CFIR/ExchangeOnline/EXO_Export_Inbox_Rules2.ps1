#
Get-Mailbox -resultsize unlimited  |
foreach {
    Write-Verbose "Checking $($_.alias)..." -Verbose
    $inboxrule = get-inboxrule -Mailbox $_.alias  
    if ($inboxrule) {
        foreach($rule in $inboxrule){
        [PSCustomObject]@{
            Mailbox         = $_.alias
            Rulename        = $rule.name
            Rulepriority    = $rule.priority
            Ruledescription = $rule.description
        }
    }
    }
} | 
Export-csv -Path "/users/ellishlomo/Downloads/InboxRules.csv" -NoTypeInformation