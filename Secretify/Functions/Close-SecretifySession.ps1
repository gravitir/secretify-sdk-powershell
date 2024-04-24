<#
.SYNOPSIS
    Closes the current Secretify session by clearing session data.

.DESCRIPTION
    The Close-SecretifySession function terminates a Secretify session by clearing all session-related data stored in the `$SecretifySession` variable. 
    This action resets all session-specific settings and information, effectively logging out the user from the current session.

.PARAMETER None
    This function does not accept any parameters.

.EXAMPLE
    Close-SecretifySession
    Demonstrates how to use the Close-SecretifySession function to clear the current session data and ensure a clean logout from the Secretify service.

.NOTES
    It is recommended to invoke this function at the end of any script or session interacting with the Secretify service to ensure that all temporary session data is securely cleared. 
    This practice enhances security by preventing potential session data leakage.

.OUTPUTS
    None
    This function does not produce any output; it solely performs the action of clearing session data. 
    It provides verbose feedback when the session is successfully closed and error messages if the operation fails.
#>
function Close-SecretifySession {
    try {
        $SecretifySession.Clear()
        Write-Verbose "Secretify session successfully closed."
    }
    catch {
        throw "Failed to close Secretify session. Error: $($_.Exception.Message)"
    }
}
