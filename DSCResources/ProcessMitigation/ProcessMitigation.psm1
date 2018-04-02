

$script:localizedData = Get-LocalizedData -ResourceName 'ProcessMitigation'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $MitigationTarget,

        [Parameter()]
        [string[]]
        $Enable,

        [Parameter()]
        [string[]]
        $Disable
    )

    Import-Module -Name ProcessMitigations -Verbose:0

    $results = @()
    $mitigationsToCheck = $Enable + $Disable
    $policyStrings = [Microsoft.Samples.PowerShell.Commands.AppMitigations].GetProperties().Name

    if ($MitigationTarget -eq 'System')
    {
        $currentMitigation = Get-ProcessMitigation -System
    }
    else
    {
        $currentMitigation = Get-ProcessMitigation -Name $MitigationTarget
    }

    foreach ($mitigation in $mitigationsToCheck)
    {
        if ($null -ne $currentMitigation.$mitigation.Enable)
        {
            $results += @{
                Mitigation = $mitigation
                Value      = $currentMitigation.$mitigation.Enable
            }
        }
        else
        {
            foreach ($policy in $policyStrings)
            {
                if ($null -ne $currentMitigation.$policy.$mitigation )
                {
                    $results += @{
                        Mitigation = $mitigation
                        Value      = $currentMitigation.$policy.$mitigation
                    }
                }
            }
        }
    }

        $enableResults  = Get-ProcessMitgationResult -RawResult $results -ResultType Enable
        $disableResults = Get-ProcessMitgationResult -RawResult $results -ResultType Disable
        $defaultResults = Get-ProcessMitgationResult -RawResult $results -ResultType Default

    $returnValue = @{
        MitigationTarget = $MitigationTarget
        Enable           = [string[]]$enableResults
        Disable          = [string[]]$disableResults
        Default          = [string[]]$defaultResults
    }
    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $MitigationTarget,

        [string[]]
        $Enable,

        [string[]]
        $Disable
    )

    $PSBoundParameters.Remove('MitigationTarget')

    if ($MitigationTarget -eq 'System')
    {
        Set-ProcessMitigation -System @PSBoundParameters
    }
    else
    {
        Set-ProcessMitigation -Name $MitigationTarget @PSBoundParameters
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $MitigationTarget,

        [string[]]
        $Enable,

        [string[]]
        $Disable
    )

    $inDesiredState = $true
    $currentState = Get-TargetResource @PSBoundParameters

    # verify policies in Enable are in a desired state
    foreach ( $policy in $Enable )
    {
        if ( $policy -notin $currentState.Enable )
        {
            Write-Verbose -Message ($script:localizedData.policyNotInDesiredStateEnabled -f $policy)
            $inDesiredState = $false
        }
    }

    # verify policies in Disable are in a desired state
    foreach ( $policy in $Disable )
    {
        if ( $policy -notin $currentState.Disable )
        {
            Write-Verbose -Message ($script:localizedData.policyNotInDesiredStateDisabled -f $policy)
            $inDesiredState = $false
        }
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Ensure the results are not an empty collection. Get-DscConfiguration will fail if the return result do not match the schema.mof
    .PARAMETER RawResult
        A hastable of the results to filter
    .PARAMETER ResultType
        Specifies if we want to filter for mitgations policies that are Enable, Disable, or in the Default status.
#>
function Get-ProcessMitgationResult
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]
        $RawResult,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable', 'Default')]
        [string]
        $ResultType
    )

    $resultTypeEnum = @{
        Enable  = 'ON'
        Disable = 'OFF'
        Default = 'NOTSET'
    }

    $result = @( ( $results | Where-Object -FilterScript { $PSItem.Value -eq $resultTypeEnum[$ResultType] } ).Mitigation )

    if ( [string]::IsNullOrEmpty($result) )
    {
        return $null
    }
    else
    {
        return $result
    }
}

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.        
#>
function Get-LocalizedData
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'resource')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'helper')]
        [ValidateNotNullOrEmpty()]
        [String]
        $HelperName
    )

    # With the helper module just update the name and path variables as if it were a resource. 
    if ($PSCmdlet.ParameterSetName -eq 'helper')
    {
        $resourceDirectory = $PSScriptRoot
        $ResourceName = $HelperName
    }
    else 
    {
        # Step up one additional level to build the correct path to the resource culture.
        $resourceDirectory = Join-Path -Path ( Split-Path $PSScriptRoot -Parent ) `
                                       -ChildPath $ResourceName
    }

    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

Export-ModuleMember -Function *-TargetResource
