# This section suppresses rules PsScriptAnalyzer may catch in stub functions. 
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '')]
param ()

<#
    .SYNOPSIS
        This is stub cmdlets for module: ProcessMitigations version: 1.0.11 which can be used in
        Pester unit tests to be able to test code without having the actual module installed.

    .NOTES
        Generated from module System.Collections.Hashtable on
        operating system Microsoft Windows 10 Pro 64-bit (10.0.17134)
#>
function ConvertTo-ProcessMitigationPolicy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $EMETFilePath,

        [Parameter(Mandatory = $true)]
        [string]
        $OutputFilePath
    )

    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

<#
    .SYNOPSIS
        This is stub cmdlets for module: ProcessMitigations version: 1.0.11 which can be used in
        Pester unit tests to be able to test code without having the actual module installed.

    .NOTES
        Generated from module System.Collections.Hashtable on
        operating system Microsoft Windows 10 Pro 64-bit (10.0.17134)
#>
function Get-ProcessMitigation
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'NameMode')]
        [string]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'IdMode')]
        [int[]]
        $Id,

        [Parameter(ParameterSetName = 'SaveMode')]
        [string]
        $RegistryConfigFilePath,

        [Parameter(ParameterSetName = 'NameMode')]
        [switch]
        $RunningProcesses,

        [Parameter(ParameterSetName = 'SystemMode')]
        [switch]
        $System,

        [Parameter(ParameterSetName = 'FullPolicy')]
        [switch]
        $FullPolicy
    )

    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

<#
    .SYNOPSIS
        This is stub cmdlets for module: ProcessMitigations version: 1.0.11 which can be used in
        Pester unit tests to be able to test code without having the actual module installed.

    .NOTES
        Generated from module System.Collections.Hashtable on
        operating system Microsoft Windows 10 Pro 64-bit (10.0.17134)
#>
function Set-ProcessMitigation
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [string]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'FullPolicy')]
        [string]
        $PolicyFilePath,

        [Parameter(ParameterSetName = 'FullPolicy')]
        [switch]
        $IsValid,

        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [Parameter(ParameterSetName = 'SystemMode')]
        [string[]]
        $Disable,

        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [Parameter(ParameterSetName = 'SystemMode')]
        [string[]]
        $Enable,

        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [Parameter(ParameterSetName = 'SystemMode')]
        [string[]]
        $EAFModules,

        [Parameter(ParameterSetName = 'SystemMode')]
        [switch]
        $System,

        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [Parameter(ParameterSetName = 'SystemMode')]
        [string]
        $Force,

        [Parameter(ParameterSetName = 'SystemMode')]
        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [switch]
        $Reset,

        [Parameter(ParameterSetName = 'ProcessPolicy')]
        [Parameter(ParameterSetName = 'SystemMode')]
        [switch]
        $Remove
    )

    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
}

