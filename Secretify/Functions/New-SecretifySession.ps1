<#
.SYNOPSIS
    Authenticates with a specified URL and retrieves an access token for managing API sessions.

.DESCRIPTION
    This function authenticates by sending client credentials to a specific URL and retrieves an access token. The access token is necessary for authorizing subsequent API calls.

.PARAMETER Url
    Specifies the base URL of the API for which authentication is being performed. This URL should direct to the API's authentication endpoint.

.PARAMETER Username
    The client identifier as registered with the API's identity provider. This ID is unique to the client and is used to identify it during the authentication process.

.PARAMETER Password
    The secret associated with the client identifier. This should be protected as it is used to secure the authentication process.

.EXAMPLE
    $token = New-SecretifySession -Url "https://secretify.com" Username "myUseranme" Password "myPassword"
    This example demonstrates how to authenticate and store the returned access token in the session.

.NOTES
    Ensure that the API endpoint and credentials are correct. Verify that the client ID and client secret are kept secure to prevent unauthorized access.
#>

function New-SecretifySession {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter()]
        [string]$Username,

        [Parameter()]
        [string]$Password
    )

    if (!$Username -and !$Password) {
        if ($PSCmdlet.ShouldProcess("Authenticating with $Url", "Without authentication")) {
            $healthcheckUrl = "$Url/api/v1"
            try {
                Write-Verbose "Attempting healthcheck to $healthcheckUrl"
                $response = Invoke-RestMethod -Uri $healthcheckUrl -Method Get -StatusCodeVariable statusCode 

                if ($statusCode -eq 200) {
                    Write-Verbose "Healthcheck was successfully"
                    $SecretifySession.Authenticated = $false
                    $SecretifySession.ApiVersion = "v1"
                    $SecretifySession.Url = $Url
        
                    return [ordered]@{
                        Authenticated = $SecretifySession.Authenticated
                        StartTime     = $null
                        Username      = $null
                        URL           = $SecretifySession.Url
                        RemainingTime = $null
                    }
                }
                else {
                    throw "Failed healthcheck. Error: $response"
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
            client_id     = $Username
            client_secret = $Password
        } | ConvertTo-Json

        try {
            Write-Verbose "Attempting to authenticate to $authUrl"
            $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json" -StatusCodeVariable statusCode 

            if ($statusCode -eq 200 && $response.data.access_token) {
                Write-Verbose "Access Token obtained successfully"
                $SecretifySession.Authenticated = $true
                $SecretifySession.Username = $Username
                $SecretifySession.ApiVersion = "v1"
                $SecretifySession.AuthToken = $response.data.access_token
                $SecretifySession.StartTime = Get-Date
                $SecretifySession.Url = $Url
                
                # Return newly created session
                return [ordered]@{
                    Authenticated = $SecretifySession.Authenticated
                    StartTime     = $SecretifySession.StartTime
                    Username      = $SecretifySession.Username
                    URL           = $SecretifySession.Url
                    RemainingTime = ($SecretifySession.StartTime.AddHours(1) - (Get-Date)).ToString("hh\:mm\:ss")
                }
            }
            else {
                throw "Failed to authenticate. Error: $response"
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
