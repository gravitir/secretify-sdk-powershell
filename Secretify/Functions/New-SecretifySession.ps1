<#
.SYNOPSIS
    Authenticates with a specified URL and retrieves an access token for managing API sessions.

.DESCRIPTION
    This function authenticates by sending client credentials to a specific URL and retrieves an access token. The access token is necessary for authorizing subsequent API calls.

.PARAMETER Url
    Specifies the base URL of the API for which authentication is being performed. This URL should direct to the API's authentication endpoint.

.PARAMETER ClientId
    The client identifier as registered with the API's identity provider. This ID is unique to the client and is used to identify it during the authentication process.

.PARAMETER ClientSecret
    The secret associated with the client identifier. This should be protected as it is used to secure the authentication process.

.EXAMPLE
    $token = New-SecretifySession -Url "https://secretify.com" -ClientId "myClientId" -ClientSecret "myClientSecret"
    This example demonstrates how to authenticate and store the returned access token in the session.

.NOTES
    Ensure that the API endpoint and credentials are correct. Verify that the client ID and client secret are kept secure to prevent unauthorized access.
#>

function New-SecretifySession {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [Alias("ID")]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [Alias("Secret")]
        [string]$ClientSecret
    )

    if ($PSCmdlet.ShouldProcess("Authenticating with $Url", "Request access token")) {
        $authUrl = "$Url/api/v1/auth/microsoftonline"
        $authBody = @{
            grant_type    = "client_credentials"
            client_id     = $ClientId
            client_secret = $ClientSecret
        } | ConvertTo-Json

        try {
            Write-Verbose "Attempting to authenticate to $authUrl"
            $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/json" -StatusCodeVariable statusCode 

            if ($statusCode -eq 200 && $response.data.access_token) {
                Write-Verbose "Access Token obtained successfully"
                $SecretifySession.ClientId = $ClientId
                $SecretifySession.ApiVersion = "v1"
                $SecretifySession.AuthToken = $response.data.access_token
                $SecretifySession.StartTime = Get-Date
                $SecretifySession.Url = $Url
                
                # Create a hashtable to display session information
                return @{
                    "Session Started At" = $SecretifySession.StartTime
                    "Client ID" = $SecretifySession.ClientId
                    "URL" = $SecretifySession.Url
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
