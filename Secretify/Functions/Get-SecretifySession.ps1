<#
.SYNOPSIS
    Displays the current Secretify session information.

.DESCRIPTION
    This function prints out the detailed information of the current Secretify session stored in the `$SecretifySession` hashtable.

.PARAMETER none
    This function does not take any parameters.
    
.EXAMPLE
    Get-SecretifySession 
    Displays the current session information.

.NOTES
    This function assumes that the `$SecretifySession` object is properly initialized with all necessary session information. Make sure that this hashtable is populated before calling the function.
#>

function Get-SecretifySession {
    [CmdletBinding()]
    param ()

    # Check if the SecretifySession hashtable has been initialized
    if ($null -eq $SecretifySession -or $null -eq $SecretifySession.StartTime) {
        throw "SecretifySession has not been initialized. Please initialize the session first."
    }

    # Create a hashtable to display session information
    # Using the [ordered] type accelerator to keep the keys in the order they are added
    return [ordered]@{
        "Session Started At" = $SecretifySession.StartTime
        "Client ID" = $SecretifySession.ClientId
        "URL" = $SecretifySession.Url
        "Remaining Time" = ($SecretifySession.StartTime.AddHours(1) - (Get-Date)).ToString("hh\:mm\:ss")
    }
}