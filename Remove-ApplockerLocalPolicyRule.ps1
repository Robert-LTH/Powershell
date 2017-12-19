function Remove-ApplockerLocalPolicyRule {
    param(
        [string]$RuleName
    )
    $EffectivePolicy = Get-AppLockerPolicy -Local
    # Can not delete while enumerating, create array for later use
    $RulesToDelete = @()
    # Process all collections
    $EffectivePolicy.RuleCollections | % {
        $RuleCollection = $_
        # Process all rules in current collection
        $RuleCollection | Where-Object { $_.Name -match $RuleName } | ForEach-Object { $RulesToDelete += $_.Id }
        # Delete the rules found in this collection
        $RulesToDelete | ForEach-Object { $RuleCollection.Delete($_) }
    }
    # Save the policy
    $EffectivePolicy | Set-AppLockerPolicy
}
