@{
    ModuleVersion     = '1.0'
    GUID              = '8158d204-6b45-4654-b123-4fad0e1d6e5e'
    Author            = 'Gravitir AG'
    CompanyName       = 'Gravitir AG'
    Copyright         = 'Copyright (c) 2024 Gravitir AG. All rights reserved.'
    Description       = 'Module for Secretify API' 
    PowerShellVersion = '7.0'
    RootModule        = 'Secretify.psm1'

    FunctionsToExport = @(  'New-SecretifySession',
                            'Close-SecretifySession',
                            'Get-SecretifySession', 
                            'New-SecretifySecret', 
                            'Read-SecretifySecret',
                            'Get-SecretifySecretType')

    NestedModules     = @('.\Private\Crypto.ps1')
    #VariablesToExport = @('*')  # Export all variables if needed
    #AliasesToExport   = @()  # Define any aliases for your functions if needed
    # Add other needed properties as seen in your provided example
}
