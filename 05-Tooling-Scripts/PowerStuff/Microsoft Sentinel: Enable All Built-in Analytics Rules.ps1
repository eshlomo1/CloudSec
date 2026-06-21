# Automate Microsoft Sentinel: Enable All Built-in Analytics Rules with PowerShell
# This PowerShell script automates the creation and activation of all built-in Microsoft Sentinel analytics rules from rule templates. 
# It dynamically handles different rule types (Scheduled, Fusion, MLBehaviorAnalytics, MicrosoftSecurityIncidentCreation) and ensures correct configurations while bypassing unsupported parameters. 
# With built-in error handling, it continues execution even if some tables are missing, making it an efficient tool for SOC teams and Azure Security Engineers to quickly operationalize Sentinel detections.

# Running this script modifies Microsoft Sentinel analytics rules. Please consider the following important warnings before execution:Run a Dry Run First, Be Aware of Null Values, and Changes May Take Time to Reflect in the Portal.

# --------------

# Install Az.SecurityInsights module if not installed
if (-not (Get-Module -ListAvailable -Name Az.SecurityInsights)) {
    Install-Module Az.SecurityInsights -Force -AllowClobber
}

# Connect to Azure
Connect-AzAccount

# Set required variables
$resourceGroupName = "XXXXXX"
$workspaceName = "XXXXXX"

# Get all built-in rule templates
$ruleTemplates = Get-AzSentinelAlertRuleTemplate -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName

if ($ruleTemplates.Count -eq 0) {
    Write-Host "No built-in rule templates found in Microsoft Sentinel." -ForegroundColor Yellow
    return
}

Write-Host "Found $($ruleTemplates.Count) rule templates. Creating analytics rules..." -ForegroundColor Green

foreach ($template in $ruleTemplates) {
    try {
        Write-Host "Creating rule from template: $($template.DisplayName) (Kind: $($template.Kind))"

        # Define common parameters
        $ruleParams = @{
            ResourceGroupName = $resourceGroupName
            WorkspaceName     = $workspaceName
            DisplayName       = $template.DisplayName
            Enabled           = $true
        }

        # Handle different rule kinds
        switch ($template.Kind) {
            "Scheduled" {
                $ruleParams["Kind"] = "Scheduled"
                $ruleParams["Severity"] = "Medium"
                $ruleParams["Query"] = $template.Query  # Uses the rule template query

                # Convert time values to proper TimeSpan format
                $ruleParams["QueryFrequency"] = [System.TimeSpan]::FromHours(1)  # 1 hour
                $ruleParams["QueryPeriod"] = [System.TimeSpan]::FromDays(1)  # 1 day

                # Ensure only valid suppression settings are applied
                if ($template.PSObject.Properties.Name -contains "SuppressionEnabled") {
                    $ruleParams["SuppressionEnabled"] = $false
                    $ruleParams["SuppressionDuration"] = [System.TimeSpan]::FromHours(1)
                }

                # Fix 'Tactics' error - Only include if available
                if ($template.PSObject.Properties.Name -contains "Tactics") {
                    $ruleParams["Tactics"] = $template.Tactics
                }

                # Required for Scheduled rules
                $ruleParams["TriggerOperator"] = "GreaterThan"
                $ruleParams["TriggerThreshold"] = 5  # Default threshold, modify as needed
            }
            "MicrosoftSecurityIncidentCreation" {
                $ruleParams["Kind"] = "MicrosoftSecurityIncidentCreation"
                if ($template.PSObject.Properties.Name -contains "ProductFilter") {
                    $ruleParams["ProductFilter"] = $template.ProductFilter
                }
            }
            "Fusion" {
                $ruleParams["Kind"] = "Fusion"
            }
            "MLBehaviorAnalytics" {
                $ruleParams["Kind"] = "MLBehaviorAnalytics"
            }
            "NRT" {
                Write-Host "Skipping NRT rule: $($template.DisplayName) as it requires a different setup."
                continue
            }
            default {
                Write-Host "Skipping unsupported rule kind: $($template.Kind)"
                continue
            }
        }

        # Try creating the rule
        try {
            New-AzSentinelAlertRule @ruleParams
            Write-Host "Successfully created and enabled rule: $($template.DisplayName)"
        } catch {
            if ($_.Exception.Message -match "Table not found") {
                Write-Host "Warning: Table not found for $($template.DisplayName), but continuing..."
            } else {
                Write-Host "Failed to create rule from template: $($template.DisplayName). Error: $_"
            }
        }

    } catch {
        Write-Host "Unexpected error processing rule template: $($template.DisplayName). Error: $_"
    }
}

Write-Host "All built-in analytics rules have been processed."
