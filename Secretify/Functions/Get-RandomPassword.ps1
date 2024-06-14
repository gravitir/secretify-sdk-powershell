<#
.SYNOPSIS
Generates a random password based on specified criteria.

.DESCRIPTION
The Get-RandomPassword function generates a random password with a specified length
and includes options to include numbers, symbols, lowercase letters, and uppercase letters.
The function constructs a character pool based on the parameters provided and randomly 
selects characters to create the password.

.PARAMETER Length
Specifies the length of the generated password. Default value is 30.

.PARAMETER IncludeNumbers
Indicates whether the generated password should include numbers. Default value is $true.

.PARAMETER IncludeSymbols
Indicates whether the generated password should include symbols. Default value is $true.

.PARAMETER IncludeLowercase
Indicates whether the generated password should include lowercase letters. Default value is $true.

.PARAMETER IncludeUppercase
Indicates whether the generated password should include uppercase letters. Default value is $true.

.EXAMPLE
PS> Get-RandomPassword -Length 12 -IncludeNumbers $true -IncludeSymbols $true -IncludeLowercase $true -IncludeUppercase $true
Generates a 12-character password including numbers, symbols, lowercase, and uppercase letters.

.EXAMPLE
PS> Get-RandomPassword -Length 8 -IncludeNumbers $false -IncludeSymbols $false -IncludeLowercase $true -IncludeUppercase $true
Generates an 8-character password including only lowercase and uppercase letters.

.NOTES
The function ensures that at least one type of character must be included in the character pool.
If no character types are included, the function will throw an error.
#>

function Get-RandomPassword {
    [CmdletBinding()]
    param (
        [int]$Length = 30,
        [bool]$IncludeNumbers = $true,
        [bool]$IncludeSymbols = $true,
        [bool]$IncludeLowercase = $true,
        [bool]$IncludeUppercase = $true
    )

    # Define character sets as arrays
    $numbers = @('0','1','2','3','4','5','6','7','8','9')
    $symbols = @('!','@','#','$','^','*','(',')','_','+','-','=','[',']','{','}',';',':',',','.','?')
    $lowercase = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
    $uppercase = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

    # Build the combined character pool based on the parameters
    $FullSet = @()
    if ($IncludeNumbers) { $FullSet += $numbers }
    if ($IncludeSymbols) { $FullSet += $symbols }
    if ($IncludeLowercase) { $FullSet += $lowercase }
    if ($IncludeUppercase) { $FullSet += $uppercase }

    # Check if the character pool is empty
    if (-not $FullSet) {
        throw "At least one character type must be included."
    }

    # Generate the random password
    $PasswordArray = 1..$Length | ForEach-Object { $FullSet | Get-Random }
    $Password = -join $PasswordArray

    return $Password
}
