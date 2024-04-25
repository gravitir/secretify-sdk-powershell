![Alt text](assets/icon-64.png?raw=true "Title")

# Secretify PowerShell SDK

## Prerequisites

Before you begin, ensure that you have the following prerequisites in place:

* **PowerShell 7.0 or higher**: Make sure you have PowerShell version 7.0 or above installed on your system.
* **Running Secretify Instance with Configured Microsoft Entra**: Ensure that you have a Secretify instance up and running, with Microsoft Entra properly configured.
* **Microsoft Entra Client Credentials for Authentication**: Obtain client credentials from Microsoft Entra for authentication purposes. Secretify utilizes the Client Credentials OAuth2 flow for authentication.

## Installation

### Option 1: Install from PowerShell Gallery

The easiest and most recommended method to install the Secretify module is via the PowerShell Gallery.

1. Open a PowerShell prompt.
2. Run the following command:

    ```powershell
    Install-Module -Name Secretify
    ```

### Option 2: Manual Installation

If you prefer manual installation, follow these steps:

1. Locate your PowerShell module directories by running the following command in PowerShell:

    ```powershell
    $env:PSModulePath -split ';'
    ```

2. Copy the module files to one of the listed directories. Ensure that they are placed within a folder named `Secretify`.

    - You can download the module files from [PowerShell Gallery](https://www.powershellgallery.com/packages/Secretify) or this git repository under `./Secretify`.
    - After downloading, extract the files and place them in the designated PowerShell module directory.

### Verify Installation

Ensure the module is installed:

```powershell
Get-Module -ListAvailable Secretify
```

Import the module:

```powershell
Import-Module Secretify
```

List Module Commands:

```powershell
Get-Command -Module Secretify
```

Get detailed information on specific commands:

```powershell
Get-Help Secretify
```

## Usage

### Authenticate

To authenticate with Secretify, use the `New-SecretifySession` cmdlet. This cmdlet submits a logon request to the Secretify API and establishes a session for subsequent operations.

```powershell
$cred = Get-Credential

New-SecretifySession -Url "https://example.secretify.io" -ClientId $cred.UserName -ClientSecret $cred.GetNetworkCredential().Password
```


### Create secret

To create a secret using the Secretify module, utilize the `New-SecretifySecret` cmdlet. This cmdlet allows you to specify the data, type identifier, expiration time, views, and other parameters for the secret to be created.

```powershell
$data = @{
    message  = "This is a secure message"
}

$secret = New-SecretifySecret -Data $data -TypeIdentifier "text" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false
```

Alternatively, if you have configured a custom secret type such as `credentials`, you can create a secret of that type:

```powershell
$data = @{
    username       = "tony.stark"
    password       = "v3ry@S3!cure"
}

$secret = New-SecretifySecret -Data $data -TypeIdentifier "credentials" -ExpiresAt "24h" -Views 2 -IsDestroyable $true -HasPassphrase $false
```

### Reveal secret

To reveal a secret, use the `Read-SecretifySecret` cmdlet. You can reveal a secret either by providing its URL or by specifying its identifier and key.


```powershell
Read-SecretifySecret -Url $secret.Link
```

or


```powershell
Read-SecretifySecret -Identifier $secret.Identifier -Key $secret.Key
```

### Logout

To close the Secretify session and log out, use the `Close-SecretifySession` cmdlet.

```powershell
Close-SecretifySession
```
