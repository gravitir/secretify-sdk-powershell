<#
.SYNOPSIS
    Retrieves and decrypts a secret from a secure store based on a provided URL, or a combination of identifier and key.

.DESCRIPTION
    This function allows for flexible retrieval and decryption of secrets:
    - If a complete secret link is provided (including both the identifier and decryption key), the function parses the URL to extract these components and uses them to retrieve the secret.
    - If an identifier and key are provided separately, it uses the session's base URL combined with these details to fetch and decrypt the secret.

.PARAMETER Url
    The full URL to the secret. If only the identifier and key are provided, the session's base URL will be used. This parameter is optional if both Identifier and Key are provided.

.PARAMETER Identifier
    The unique identifier for the secret to be retrieved. This parameter is required if the Key is provided without a complete URL.

.PARAMETER Key
    The decryption key required to access the secret. This parameter is required if Identifier is provided.

.EXAMPLE
    Read-SecretifySecret -Url "https://secretify.com/s/12345#keyHere"
    This command parses the complete URL to extract the base URL, identifier, and decryption key to retrieve the secret.

.EXAMPLE
    Read-SecretifySecret -Identifier "abc123" -Key "s3cr3t"
    This command uses the session's base URL to retrieve the secret identified by "abc123" with the decryption key "s3cr3t".

.OUTPUTS
    PSCustomObject
    Returns a decrypted secret object retrieved from the secure storage service.

.NOTES
    Ensure that appropriate parameters are provided to successfully retrieve and decrypt the secret. At least an Identifier and Key are required unless a complete secret link is provided.
#>

function Read-SecretifySecret {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Url,

        [Parameter(Mandatory=$false)]
        [string]$Identifier,

        [Parameter(Mandatory=$false)]
        [string]$Key
    )

    try {
        $headers = @{
            "Authorization" = "Bearer $($SecretifySession.AuthToken)"
            "Content-Type"  = "application/json"
        }

        if ($Url -match '\/s\/.+?#')  {
            # Assuming the URL is a complete secret link
            $secretLinkParts = $Url -split '#'
            $baseUrl = $secretLinkParts[0] -replace '\/s\/.*$', ''
            $identifier = $secretLinkParts[0] -replace '^.*\/s\/', ''
            $key = $secretLinkParts[1]
            
            $secretUrl = "$baseUrl/api/v1/secret/$Identifier/_cipher"
            Write-Verbose "Parsed URL for Base URL: $baseUrl, Identifier: $identifier, Key: $key"

        } elseif ($Identifier -and $Key) {
            $secretUrl = "$($SecretifySession.Url)/api/v1/secret/$Identifier/_cipher"
        } else {
            Write-Error "Insufficient parameters provided to retrieve and decrypt the secret."
            return $null
        }


        Write-Verbose "Retrieving encrypted data from $secretUrl"
        $response = Invoke-RestMethod -Uri $secretUrl -Method Get -Headers $headers -StatusCodeVariable statusCode

        if ($statusCode -ne 200) {
            Write-Error "Failed to retrieve secret. Error: $statusCode"
            return
        }
        $cipher = $response.data.cipher | ConvertFrom-Json
        Write-Debug "Cipher object: $(ConvertTo-Json -InputObject $cipher)"

        $decryptedAttributes = @{}
        $decryptionKey = ConvertFrom-Base64Url -base64Url $Key

        foreach ($attributeName in $cipher.PSObject.Properties.Name) {
            $encryptedData = $cipher.$attributeName
            $decryptedData = Unprotect-String -encryptedData $encryptedData -encryptionKey $decryptionKey
            $decryptedAttributes[$attributeName] = $decryptedData
        }

        Write-Verbose "Successfully decrypted the data."
        return [PSCustomObject]$decryptedAttributes

    } catch {
        Write-Error "Failed to reveal secret. Error: $($_.Exception.Message)"
        return $null
    }
}
