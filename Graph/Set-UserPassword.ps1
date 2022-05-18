$PasswordProfile = @{
  forceChangePasswordNextSignIn = $false
  forceChangePasswordNextSignInWithMfa = $true
  password = ""
}

Connect-MgGraph -Scopes Directory.AccessAsUser.All
Update-MgUser -UserId '' -PasswordProfile $PasswordProfile
