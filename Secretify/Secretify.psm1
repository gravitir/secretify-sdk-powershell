<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

.INPUTS

.OUTPUTS
#>

[CmdletBinding()]
param()

# Optionally, define any enums or constants here if needed

# Load all function scripts
Get-ChildItem -Path $PSScriptRoot/Functions -Filter *.ps1 -Recurse | ForEach-Object {
    $ExecutionContext.InvokeCommand.InvokeScript(
        $false,
        ([scriptblock]::Create([io.file]::ReadAllText($_.FullName, [Text.Encoding]::UTF8))),
        $null,
        $null
    )
}

# Define module-wide variables or session state if needed
$SecretifySession = [ordered]@{
    Authenticated       = $null
    Url                 = $null
    Username            = $null
    ApiVersion          = $null
    AuthToken           = $null
    StartTime           = $null
    Proxy               = $null
    #LastCommand         = $null
    #LastCommandTime     = $null
    #LastCommandResults  = $null
    #RefreshTime         = $null
}
New-Variable -Name SecretifySession -Value $SecretifySession -Scope Script -Force