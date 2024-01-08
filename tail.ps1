function tail {
    param(
        $FilePath,
        $InitialRows = 10
    )

    Get-Content -Tail $InitialRows -Wait -Path $FilePath
}
