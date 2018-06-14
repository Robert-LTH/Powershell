function Get-GHLatestReleaseUri {
    param(
        $Owner,
        $Repository
    )
    $Headers = @{
        # https://developer.github.com/v3/#user-agent-required
        'user-agent' = ''
        # https://developer.github.com/v3/#timezones
        'Time-Zone' = ''
    }
    $BaseUri = 'https://api.github.com'
    Invoke-RestMethod -ErrorAction Stop -Method GET -UseBasicParsing -Uri "$BaseUri/repos/$Owner/$Repository/releases/latest" -Headers $Headers  | Select-Object -ErrorAction SilentlyContinue -ExpandProperty assets | ? { $_.name -match '64-bit.exe'} | Select-Object -ExpandProperty browser_download_url
}
