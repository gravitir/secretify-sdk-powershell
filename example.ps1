Remove-Module Secretify
Import-Module .\Secretify.psd1

$Url = "https://lab.secretify.io"
$cred = Get-Credential -Message "Enter your Secretify credentials"

#####################  Start a new Session #####################
Write-Host "`nNew Session Starting" -ForegroundColor red
New-SecretifySession -Url $Url -Credential $cred


#####################  Get the secret types #####################
#Write-Host "`nAvailable secret types" -ForegroundColor red
#$types = Get-SecretifySecretType
#Write-output $types

#####################  Create a secret with text #####################

# Define the hashtable for a Message type secret
$data = @{
    message  = "This is a secure message"
}

# Call the function with parameters hashtable
Write-Host "`nCreating New Secret Message" -ForegroundColor red 
$return = New-SecretifySecret -Data $data -TypeIdentifier "text" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false 
$return

## Reveal the secret
Write-Host "`nRevealing secret with link: $($return.Link)" -ForegroundColor Cyan
Read-SecretifySecret -Url $return.Link

Write-Host "`nRevealing secret with Identifier: $($return.Identifier) and Key: $($return.Key)" -ForegroundColor Cyan
Read-SecretifySecret -Identifier $return.Identifier -Key $return.Key


#####################  Create a secret with credentials #####################

# Define the hashtable for a Credential type secret
$data = @{
    username       = "user123"
    password       = "pass123"
}

# Call the function with parameters hashtable
Write-Host "`nCreating New Secret Credential" -ForegroundColor red 
$return = New-SecretifySecret -Data $data -TypeIdentifier "credentials" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false 
$return

## Reveal the secret
Write-Host "`nRevealing secret with link: $($return.Link)" -ForegroundColor Cyan
Read-SecretifySecret -Url $return.Link

Write-Host "`nRevealing secret with Identifier: $($return.Identifier) and Key: $($return.Key)" -ForegroundColor Cyan
Read-SecretifySecret -Identifier $return.Identifier -Key $return.Key

#####################  Close Session #####################
Write-Host "`nClosing Session" -ForegroundColor red
Close-SecretifySession