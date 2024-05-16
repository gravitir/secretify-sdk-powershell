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
    if ($null -eq $SecretifySession -or $SecretifySession.Count -eq 0 -or !$SecretifySession.Url) {
        throw "SecretifySession has not been initialized. Please initialize the session first."
    }

    # Create a hashtable to display session information
    return [ordered]@{
        Authenticated = if ($null -ne $SecretifySession.Authenticated) { $SecretifySession.Authenticated } else { $null }
        StartTime     = if ($SecretifySession.StartTime) { $SecretifySession.StartTime } else { $null }
        Username      = if ($SecretifySession.Username) { $SecretifySession.Username } else { $null }
        URL           = $SecretifySession.Url
        Proxy         = if ($SecretifySession.Proxy) { $SecretifySession.Proxy } else { $null }
        RemainingTime = if ($SecretifySession.StartTime) {
                            ($SecretifySession.StartTime.AddHours(1) - (Get-Date)).ToString("hh\:mm\:ss")
        }
        else {
            $null
        }
    }
}