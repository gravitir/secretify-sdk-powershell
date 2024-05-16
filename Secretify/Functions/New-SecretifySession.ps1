<#
.SYNOPSIS
    Authenticates with a specified URL and retrieves an access token for managing API sessions.

.DESCRIPTION
    This function authenticates by sending client credentials to a specific URL and retrieves an access token. The access token is necessary for authorizing subsequent API calls.

.PARAMETER Url
    Specifies the base URL of the API for which authentication is being performed. This URL should direct to the API's authentication endpoint.

.PARAMETER Credential
    Specifies the PSCredential object containing the client identifier and secret. The client identifier is the username, and the secret is the password.

.PARAMETER Proxy
    Optional. Specifies the proxy server to use for the API requests.    

.EXAMPLE
    $token = New-SecretifySession -Url "https://secretify.com" -Credential $cred
    This example demonstrates how to authenticate and store the returned access token in the session.

.NOTES
    Ensure that the API endpoint and credentials are correct. Verify that the client ID and client secret are kept secure to prevent unauthorized access.
#>

function New-SecretifySession {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [PSCredential]$Credential,

        [string]$Proxy = $null
    )

    if (!$Credential) {
        if ($PSCmdlet.ShouldProcess("Authenticating with $Url", "Without authentication")) {
            $healthcheckUrl = "$Url/api/v1"
            try {
                Write-Verbose "Attempting healthcheck to $healthcheckUrl"
                if ($Proxy) {
                    $response = Invoke-RestMethod -Uri $healthcheckUrl -Method Get -Proxy $Proxy
                } else {
                    $response = Invoke-RestMethod -Uri $healthcheckUrl -Method Get
                }
                Write-Verbose "Healthcheck was successfully"
                $SecretifySession.Authenticated = $false
                $SecretifySession.ApiVersion = "v1"
                $SecretifySession.Url = $Url
                $SecretifySession.Proxy = $Proxy
    
                return [ordered]@{
                    Authenticated = $SecretifySession.Authenticated
                    StartTime     = $null
                    Username      = $null
                    URL           = $SecretifySession.Url
                    Proxy         = $SecretifySession.Proxy
                    RemainingTime = $null
                }
            }
            catch [System.Net.WebException] {
                throw "Network error occurred: $_.Exception.Message"
            }
            catch {
                throw "Failed healthcheck. Error: $_.Exception.Message"
            }
        }
    }
    elseif ($PSCmdlet.ShouldProcess("Authenticating with $Url", "Request access token")) {
        $authUrl = "$Url/api/v1/auth/microsoftonline"
        $authBody = @{
            grant_type    = "client_credentials"
            client_id     = $Credential.UserName
            client_secret = $Credential.GetNetworkCredential().Password
        } | ConvertTo-Json

        try {
            Write-Verbose "Attempting to authenticate to $authUrl"
            if ($Proxy) {
                $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json" -Proxy $Proxy
            } else {
                $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json"
            }
            Write-Verbose "Access Token obtained successfully"
            $SecretifySession.Authenticated = $true
            $SecretifySession.Username = $Credential.UserName
            $SecretifySession.ApiVersion = "v1"
            $SecretifySession.AuthToken = $response.data.access_token
            $SecretifySession.StartTime = Get-Date
            $SecretifySession.Url = $Url
            $SecretifySession.Proxy = $Proxy
            
            # Return newly created session
            return [ordered]@{
                Authenticated = $SecretifySession.Authenticated
                StartTime     = $SecretifySession.StartTime
                Username      = $SecretifySession.Username
                URL           = $SecretifySession.Url
                Proxy         = $SecretifySession.Proxy
                RemainingTime = ($SecretifySession.StartTime.AddHours(1) - (Get-Date)).ToString("hh\:mm\:ss")
            }
        }
        catch [System.Net.WebException] {
            throw "Network error occurred: $_.Exception.Message"
        }
        catch {
            throw "Failed to authenticate. Error: $_.Exception.Message"
        }
    }
}
