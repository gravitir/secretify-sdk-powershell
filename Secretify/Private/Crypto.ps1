function ConvertTo-Base64Url {
    param (
        [byte[]]$bytes
    )
    $base64 = [System.Convert]::ToBase64String($bytes)
    $base64Url = $base64 -replace '\+', '-' -replace '/', '_' -replace '='
    return $base64Url
}

function ConvertFrom-Base64Url {
    param (
        [string]$base64Url
    )
    $base64 = $base64Url -replace '-', '+' -replace '_', '/'
    $padding = 4 - ($base64.Length % 4)
    if ($padding -lt 4) {
        $base64 += '=' * $padding
    }

    $bytes = [System.Convert]::FromBase64String($base64)
    return $bytes
}


function New-EncryptionKey {
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.GenerateKey()

    $aes.Dispose()

    return (ConvertTo-Base64Url $aes.Key)
}

function Protect-String {
    param (
        [string]$textToEncrypt,
        [byte[]]$encryptionKey
    )

    # Convert the plaintext and key to byte arrays
    $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($textToEncrypt)

    # Create an AesGcm object
    $aesGcm = [Security.Cryptography.AesGcm]::new($encryptionKey)

    # Create a nonce (IV) - A nonce should never be repeated with the same key
    $nonce = New-RandomIV

    # Create a buffer to hold the ciphertext and the authentication tag
    $ciphertext = New-Object byte[] $plaintextBytes.Length  # Same length as plaintext
    $tag = [byte[]]::new(16)

    # Encrypt the plaintext and obtain the authentication tag
    $aesGcm.Encrypt($nonce, $plaintextBytes, $ciphertext, $tag, $null)

    # Concatenate the nonce, the ciphertext, and the authentication tag
    $ivAndCiphertext = $nonce + $ciphertext + $tag

    # Convert the result to Base64 for easy storage and transmission
    $encryptedBase64 = [Convert]::ToBase64String($ivAndCiphertext)

    $aesGcm.Dispose()

    $result = "data:application/octet-stream;base64," + $encryptedBase64
    return $result
}

# Function to generate a random initialization vector (IV)
function New-RandomIV {
    $randomIV = New-Object byte[] 12
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($randomIV)
    return $randomIV
}

function Unprotect-String {
    param (
        [string]$encryptedData,
        [byte[]]$encryptionKey
    )

    # Remove the base64 encoding prefix
    $base64Data = $encryptedData -replace "data:application/octet-stream;base64,", ""

    # Convert the base64-encoded string to a byte array
    $ivAndCiphertextAndTag = [System.Convert]::FromBase64String($base64Data)

    # Split the combined array into the nonce (IV) and ciphertext
    $nonceSize = 12  # The size of the nonce in bytes
    $nonce = $ivAndCiphertextAndTag[0..($nonceSize - 1)]
    $ciphertext = $ivAndCiphertextAndTag[$nonceSize..($ivAndCiphertextAndTag.Length - 17)]
    $tag = $ivAndCiphertextAndTag[($ivAndCiphertextAndTag.Length - 16)..($ivAndCiphertextAndTag.Length - 1)]

    # Create an AesGcm object
    $aesGcm = [Security.Cryptography.AesGcm]::new($encryptionKey)

    # Create a buffer to hold the plaintext
    $plaintext = [byte[]]::new($ciphertext.Length)

    # Decrypt the ciphertext
    $aesGcm.Decrypt($nonce, $ciphertext, $tag, $plaintext, $null)
    $aesGcm.Dispose()


    # Convert the resulting plaintext byte array to a string
    $decryptedText = [System.Text.Encoding]::UTF8.GetString($plaintext)

    return $decryptedText
}

# Helper function to convert Base64 to byte array
function ConvertFrom-Base64 {
    param (
        [string]$base64EncodedString
    )
    $bytes = [System.Convert]::FromBase64String($base64EncodedString)
    return $bytes
}