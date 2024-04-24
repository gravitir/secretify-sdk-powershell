<#
.SYNOPSIS
    Retrieves and displays available secret types from the Secretify service.

.DESCRIPTION
    This function queries the Secretify service API to retrieve a list of all available secret types. 
    Each secret type's identifier and description are displayed, providing insight into the different kinds of secrets that can be managed through the service.

.PARAMETER none
    This function does not take any parameters.

.EXAMPLE
    Get-SecretifySecretType
    Retrieves and displays all secret types available in the Secretify service, showing their identifiers and descriptions. 
    Useful for understanding what kinds of secrets can be created and managed.

.OUTPUTS
    None directly. Outputs to the console.
    If secret types are available, their details are displayed. If no types are found, a message indicating "No secret types found." is displayed.

.NOTES
    This function requires an active session with valid authentication details. 
    Ensure that the `$SecretifySession` variable contains valid `Url` and `AuthToken` properties before calling this function.
#>

function Get-SecretifySecretType {
    [CmdletBinding()]
    param()

    # Construct the URL to access the secret types
    $typesUrl = "$($SecretifySession.Url)/api/v1/type"

    # Prepare the HTTP headers with the authorization token
    $headers = @{
        "Authorization" = "Bearer $($SecretifySession.AuthToken)"
        "Content-Type"  = "application/json"
    }

    try {
        # Send a GET request to retrieve the secret types
        $typeResponse = Invoke-RestMethod -Uri $typesUrl -Method Get -Headers $headers

        # Check if the response contains any types data
        if ($typeResponse.data.types) {
            # Output each type's identifier and details
            return $typeResponse.data.types

        } else {
            Write-Output "No secret types found."
        }
    } catch {
        Write-Error "Failed to retrieve secret types. Error: $($_.Exception.Message)"
    }
}
