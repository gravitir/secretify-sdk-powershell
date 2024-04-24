Using module Secretify

$VerbosePreference = 'SilentlyContinue' # `Continue` for debugging else `SilentlyContinue`
$DebugPreference = 'Continue' # `Continue` for debugging else `SilentlyContinue`

# Initialize the Secretify instance
$sify = [Secretify]::new("https://lab.secretify.io")

# Read ClientSecret securely from the console
$credential = Get-Credential -Message "Enter your client credentials"
$ClientID = $credential.UserName
$ClientSecret = $credential.GetNetworkCredential().Password

# Authenticate
try {
  $sify.Authenticate($AUTH_GRANT_CLIENTCREDENTIALS, @{
      ClientID     = $ClientID
      ClientSecret = $ClientSecret
    })
}
catch {
  Write-Error "Authentication failed. Error: $($Error[0])"
  return
}

# Create a new secret
try {
  $secret = $sify.Create(
    "text", # this is the type
    @{  
      message = "Foobar"
    },
    @{
      expiresAt = "24h"
      views     = "10"
    }
  )
  
  Write-Host "Created secret:`n$($secret | ConvertTo-Json -Depth 4)"
}
catch {
  Write-Error "Creation failed. Error: $($Error[0])"
  return
}

# Reveal it here right away
$decrypted = $sify.Reveal($secret.Identifier, $secret.Key)
# $decrypted = $sify.RevealLink($secret.Link)
Write-Host "`nRevealed Message:`n$($decrypted | ConvertTo-Json -Depth 4)`n"
