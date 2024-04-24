Import-Module $PSScriptRoot\Crypto.psm1 -Force

# consts
$AUTH_GRANT_CLIENTCREDENTIALS = "client_credentials"


Export-ModuleMember -Variable AUTH_GRANT_CLIENTCREDENTIALS

function New-SecretAPI {
    param (
        [string] $apiURL,
        [int]$typeID,
        [PSCustomObject]$cipher,
        [string]$expiresAt,
        [int]$views,
        [bool]$isDestroyable,
        [bool]$isRequest,
        [bool]$hasPassphrase,
        [string]$fileIdentifiers,
        [string]$token,
        [string]$provider
    )

    $headers = @{}
    if ($token) {
        $headers.Add("Authorization", "Bearer $token")
    }

    $body = @{
        type_id        = $typeID
        cipher         = $cipher
        expires_at     = $expiresAt
        views          = $views
        is_destroyable = $isDestroyable
        is_request     = $isRequest
        has_passphrase = $hasPassphrase
    } | ConvertTo-Json

    Write-Debug "Trying with url $apiURL"

    try {
        $response = Invoke-RestMethod -Uri $apiURL -Method Post -Headers $headers -Body $body -ContentType "application/json" -SkipCertificateCheck | ConvertTo-Json -Depth 10
    }
    catch {
        throw "An error occurred during the REST API call for secret creation. Details: $_"
    }
    return $response
}

function Get-Secret-API {
    param (
        [string] $apiURL,
        [string]$identifier
    )

    $headers = @{}
    if ($token) {
        $headers.Add("Authorization", "Bearer $token")
    }

    $url = "$($apiURL)/secret/$($identifier)/_cipher"

    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ContentType "application/json" -SkipCertificateCheck  | ConvertTo-Json -Depth 10
    return $response
}

# Class

class Secretify {
    [string]$APIURL
    [string]$UIURL
    [string]$AccessToken
    [array]$Types

    Secretify([string]$URL) {
        $this.APIURL = "$($URL)/api/v1"
        $this.UIURL = $URL
        $this.Types = $null  # Initialize Types as null
        $this.InitializeTypes()
    }

    [void]InitializeTypes() {
        $typesUrl = "$($this.APIURL)/type"
        try {
            $response = Invoke-RestMethod -Uri $typesUrl -Method Get -ContentType "application/json" -SkipCertificateCheck -ErrorAction Stop
            $this.Types = $response.data.types
        }
        catch {
            throw "Failed to retrieve types. Error: $_"
        }
    }

    [void]Authenticate([string]$grantType, [hashtable]$credentials) {
        $authUrl = "$($this.APIURL)/auth/microsoftonline"
        $authBody = @{
            grant_type    = $grantType
            client_id     = $credentials.ClientID
            client_secret = $credentials.ClientSecret
        } | ConvertTo-Json

        try {
            $authResponse = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json" -SkipCertificateCheck -ErrorAction Stop  | ConvertTo-Json -Depth 10
            $authResponseObject = $authResponse | ConvertFrom-Json

            if ($authResponseObject -and $authResponseObject.data.access_token) {
                # Store the access token
                $this.AccessToken = $authResponseObject.data.access_token
            }
            else {
                throw "Failed to authenticate. Unexpected response format."
            }
        }
        catch {
            throw "Failed to authenticate. Error: $_"
        }
    }
    
    [System.Collections.Hashtable]Create([string]$typeIdentifier, [hashtable]$attributes, [hashtable]$options) {
        # Retrieve type ID based on type identifier
        $type = $this.Types | Where-Object { $_.identifier -eq $typeIdentifier }

        if ($type -eq $null) {
            throw "Invalid type identifier: $typeIdentifier"
        }
        Write-Debug "Type is $type"

        # Options
        $typeID = $type.id
        $isDestroyable = $true
        $isRequest = $false
        $hasPassphrase = $false
        $createUrl = "$($this.APIURL)/secret"
        $views = $options.views
        $expiresAt = $options.expiresAt
    
        # Generate key
        $key = New-EncryptionKey
        
        # Loop through attributes and encrypt each one
        $cipherParams = @{}
        foreach ($attributeName in $attributes.Keys) {
            $textToEncrypt = $attributes[$attributeName]
            $encryptedData = Protect-String -textToEncrypt $textToEncrypt -encryptionKey (ConvertFrom-Base64Url $key)
            $cipherParams[$attributeName] = $encryptedData
        }
    
        # Create secret via API
        $response = New-SecretAPI -apiURL $createUrl -token $this.AccessToken -typeID $typeID -cipher $cipherParams -expiresAt $expiresAt -views $views -isDestroyable $isDestroyable -isRequest $isRequest -hasPassphrase $hasPassphrase | ConvertFrom-Json

        $identifier = $response.data.identifier
        
        return @{
            Link       = "$($this.UIURL)/s/$identifier#$key"
            Identifier = $identifier
            Key        = $key
        }
    }

    [object]RevealLink([string]$secretLink) {
        # Extract identifier and key from the secret link
        $secretLinkParts = $secretLink -split '#'
        $identifier = $secretLinkParts[0] -replace '^.*\/s\/'
        $key = $secretLinkParts[1]

        Write-Debug "Extracted Identifier: $identifier"
        Write-Debug "Extracted Key: $key"

        return $this.InvokeRevealLogic($identifier, $key)
    }

    [object]Reveal([string]$identifier, [string]$key) {
        return $this.InvokeRevealLogic($identifier, $key)
    }

    [object]InvokeRevealLogic([string]$Identifier, [string]$Key) {
        $reponse = Get-Secret-API -apiURL $this.APIURL -token $this.AccessToken -identifier $Identifier | ConvertFrom-Json

        $cipher = $reponse.data.cipher | ConvertFrom-Json

        try {
            $decryptedAttributes = @{}
            foreach ($attributeName in $cipher.PSObject.Properties.Name) {
                $encryptedData = $cipher.$attributeName
                $decryptedData = Unprotect-String -encryptedData $encryptedData -encryptionKey (ConvertFrom-Base64Url $Key)
                $decryptedAttributes[$attributeName] = $decryptedData
            }
        }
        catch {
            throw 'Could not decrypt cipher attribute'
        }

        return [PSCustomObject]$decryptedAttributes
    }

}
