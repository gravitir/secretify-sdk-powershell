<#
.SYNOPSIS
Generates a random password based on specified criteria.

.DESCRIPTION
The Get-RandomPassword function generates a random password with a specified length
and includes options to include numbers, symbols, lowercase letters, and uppercase letters.
It allows excluding certain characters and ensures that at least one character from each included set is present.

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

.PARAMETER Exclude
Specifies characters to exclude from the generated password.

.EXAMPLE
PS> Get-RandomPassword -Length 12 -IncludeNumbers $true -IncludeSymbols $true -IncludeLowercase $true -IncludeUppercase $true
Generates a 12-character password including numbers, symbols, lowercase, and uppercase letters.

.EXAMPLE
PS> Get-RandomPassword -Length 8 -IncludeNumbers $false -IncludeSymbols $false -IncludeLowercase $true -IncludeUppercase $true
Generates an 8-character password including only lowercase and uppercase letters.

.EXAMPLE
PS> Get-RandomPassword -Length 10 -Exclude "()$"
Generates a 10-character password excluding the characters '(', ')', and '$'.

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
        [bool]$IncludeUppercase = $true,
        [string]$Exclude = ""
    )

    # Validate Length parameter
    if ($Length -lt 5) {
        throw "Length must be at least 5 and cannot be negative."
    }

    # Define character sets as arrays
    $numbers = @('0','1','2','3','4','5','6','7','8','9')
    $symbols = @('!','@','#','$','^','*','(',')','_','+','-','=','[',']','{','}',';',':',',','.','?')
    $lowercase = @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z')
    $uppercase = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')

    # Remove excluded characters from each set
    if ($Exclude) {
        $ExcludeArray = $Exclude.ToCharArray()
        $numbers = $numbers | Where-Object { $ExcludeArray -notcontains $_ }
        $symbols = $symbols | Where-Object { $ExcludeArray -notcontains $_ }
        $lowercase = $lowercase | Where-Object { $ExcludeArray -notcontains $_ }
        $uppercase = $uppercase | Where-Object { $ExcludeArray -notcontains $_ }
    }


    # Build the combined character pool based on the parameters
    $FullSet = @()
    $RequiredSet = @()
    if ($IncludeNumbers) { $FullSet += $numbers; $RequiredSet += ($numbers | Get-Random -Count 1) }
    if ($IncludeSymbols) { $FullSet += $symbols; $RequiredSet += ($symbols | Get-Random -Count 1) }
    if ($IncludeLowercase) { $FullSet += $lowercase; $RequiredSet += ($lowercase | Get-Random -Count 1) }
    if ($IncludeUppercase) { $FullSet += $uppercase; $RequiredSet += ($uppercase | Get-Random -Count 1) }

    # Check if the character pool is empty
    if (-not $FullSet) {
        throw "At least one character type must be included."
    }

    # Generate the random password
    $PasswordArray = 1..($Length - $RequiredSet.Count) | ForEach-Object { $FullSet | Get-Random }
    $PasswordArray += -join $RequiredSet
    $PasswordArray = $PasswordArray | Get-Random -Count $Length
    $Password = -join $PasswordArray


    return $Password
}