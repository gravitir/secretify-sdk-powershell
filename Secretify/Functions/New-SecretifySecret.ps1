<#
.SYNOPSIS
    Creates a new secret with specified attributes in a secure storage system.

.DESCRIPTION
    This function interacts with a secure storage API to create a new secret based on the provided type identifier and other attributes. 
    It supports various secret types and allows for additional configurations like expiration, view limits, and security features.

.PARAMETER Data
    A hashtable of key-value pairs representing the attributes of the secret. These attributes vary based on the secret's type.

.PARAMETER TypeIdentifier
    Specifies the type of the secret to be created, which determines how the data is processed and stored.
    Tip: Use Get-SecretifySecretType to retrieve a list of available type identifiers.

.PARAMETER ExpiresAt
    Optional. Sets the expiration time for the secret, formatted as a duration string (e.g., "24h" for 24 hours). Defaults to "24h".

.PARAMETER Views
    Optional. Defines the number of times the secret can be viewed before it becomes inaccessible. Defaults to 1.

.PARAMETER IsDestroyable
    Optional. Indicates whether the secret should be destroyed after the first retrieval. Defaults to false.

.PARAMETER HasPassphrase
    Optional. Specifies whether a passphrase is required to access the secret. Defaults to false.

.EXAMPLE
    $data = @{
        Message = "This is a secure message"
    }
    New-SecretifySecret -Data $data -TypeIdentifier "text" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false 
    This example creates a secret of type 'text' that expires in 24 hours, can be viewed twice, is destroyable, and does not require a passphrase.

.EXAMPLE
    $data = @{
        username = "tony.stark"
        password = "v3ry@S3!cure"
    }
    New-SecretifySecret -Data $data -TypeIdentifier "credentials" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false 
    This example creates a secret of type 'credentials' with similar settings as the first example, storing username and password details securely.

.OUTPUTS
    System.Collections.Hashtable
    Outputs a hashtable containing the secret's link, identifier, and decryption key.

.NOTES
    Authentication with the API is required before executing this function. Ensure that the SecretifySession object has a valid authentication token.
    Use New-SecretifySession to authenticate and store the session details before creating secrets.
#>

function New-SecretifySecret {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data,
        
        [Parameter(Mandatory)]
        [string]$TypeIdentifier,

        [string]$ExpiresAt="24h",
        [int]$Views=1,
        [bool]$IsDestroyable=$false,
        [bool]$HasPassphrase=$false
    )

    if ($PSCmdlet.ShouldProcess("Creating a secret with TypeIdentifier '$($TypeIdentifier)' at '$Url'", "CreateSecret")) {

        $headers = @{
            "Authorization" = "Bearer $($SecretifySession.AuthToken)"
            "Content-Type"  = "application/json"
        }

        $typesUrl = "$($SecretifySession.Url)/api/v1/type"

        try {
            $typeResponse = Invoke-RestMethod -Uri $typesUrl -Method Get -Headers $headers -ContentType "application/json"
            $type = $typeResponse.data.types | Where-Object { $_.identifier -eq $TypeIdentifier }
            if (-not $type) {
                throw "Invalid type identifier: $($TypeIdentifier)"
            }
        }
        catch {
            throw "Failed to retrieve types. Error: $_"
        }

        $base64UrlKey = New-EncryptionKey
        $encryptionKey = ConvertFrom-Base64Url -base64Url $base64UrlKey

        # Define the body based on the type of secret
        $body = @{
            type_id        = $type.id
            expires_at     = $ExpiresAt
            views          = $Views
            is_destroyable = $IsDestroyable
            is_request     = $false
            has_passphrase = $HasPassphrase
            cipher         = @{}
        }

        foreach ($DataName in $Data.Keys) {
            $textToEncrypt = $Data[$DataName]
            $encryptedData = Protect-String -textToEncrypt $textToEncrypt -encryptionKey $encryptionKey
            $body['cipher'][$DataName] = $encryptedData
        }

        $body = $body | ConvertTo-Json

        $APIurl = "$($SecretifySession.Url)/api/v1/secret"

        try {
            $response = Invoke-RestMethod -Uri $APIurl -Method Post -Headers $headers -Body $body -ContentType "application/json"
            return @{
                Link       = "$($SecretifySession.Url)/s/$($response.data.identifier)#$base64UrlKey"
                Identifier = $response.data.identifier
                Key        = $base64UrlKey
            }
        }
        catch {
            throw "Failed to create secret. Error: $_"
        }
    }
}
