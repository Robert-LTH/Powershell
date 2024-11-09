function Get-IsTypeAvailable {
  param(
    [Parameter(Mandatory=$true,
        Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$TypeName
  )
  return [bool](([Management.Automation.PSTypeName]$TypeName).Type)
}
