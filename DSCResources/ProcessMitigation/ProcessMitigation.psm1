$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
            -ChildPath 'WindowsDefenderDsc.ResourceHelper.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'ProcessMitigation' -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
<#
    .SYNOPSIS
        Gets the current state of a process mitigation
    .PARAMETER MitigationTarget
        Name of the process to apply mitigation settings to.
    .PARAMETER Enable
        List of mitigations to enable.
    .PARAMETER Disable
        List of mitigations to disable.
#>
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

    $results = @()
    $mitigationsToCheck = $Enable + $Disable
    $policyStrings = Get-PolicyString

    if ($MitigationTarget -eq 'System')
    {
        Write-Verbose -Message ($script:localizedData.getOnSystem)
        $currentMitigation = Get-ProcessMitigation -System
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.getOnProcess -f $MitigationTarget)
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

    $processMitigationResults  = Get-ProcessMitgationResult -RawResult $results

    $returnValue = @{
        MitigationTarget = $MitigationTarget
        Enable           = [string[]]$processMitigationResults.Enable
        Disable          = [string[]]$processMitigationResults.Disable
        Default          = [string[]]$processMitigationResults.Default
    }
    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of a process mitigation
    .PARAMETER MitigationTarget
        Name of the process to apply mitigation settings to.
    .PARAMETER Enable
        List of mitigations to enable.
    .PARAMETER Disable
        List of mitigations to disable.
#>
function Set-TargetResource
{
    [CmdletBinding()]
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

    $PSBoundParameters.Remove('MitigationTarget')

    if ($MitigationTarget -eq 'System')
    {
        Write-Verbose -Message ($script:localizedData.SetOnSystem)
        Set-ProcessMitigation -System @PSBoundParameters
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetOnProcess -f $MitigationTarget)
        Set-ProcessMitigation -Name $MitigationTarget @PSBoundParameters
    }
}

<#
    .SYNOPSIS
        Tests the current state of a process mitigation
    .PARAMETER MitigationTarget
        Name of the process to apply mitigation settings to.
    .PARAMETER Enable
        List of mitigations to enable.
    .PARAMETER Disable
        List of mitigations to disable.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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

    $inDesiredState = $true
    $currentState = Get-TargetResource @PSBoundParameters

    # verify policies in Enable are in a desired state
    foreach ($policy in $Enable)
    {
        if ($policy -notin $currentState.Enable)
        {
            Write-Verbose -Message ($script:localizedData.policyNotInDesiredStateEnabled -f $policy)
            $inDesiredState = $false
        }
    }

    # verify policies in Disable are in a desired state
    foreach ( $policy in $Disable )
    {
        if ($policy -notin $currentState.Disable)
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
#>
function Get-ProcessMitgationResult
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]
        $RawResult
    )

    [pscustomobject]@{
        Enable  = @(($RawResult | Where-Object -FilterScript { $PSItem.Value -eq 'ON' }).Mitigation)
        Disable = @(($RawResult | Where-Object -FilterScript { $PSItem.Value -eq 'OFF' }).Mitigation)
        Default = @(($RawResult | Where-Object -FilterScript { $PSItem.Value -eq 'NOTSET' }).Mitigation)
    }
}

<#
    .SYNOPSIS
        Returns all the possible mitigation policy strings
#>
function Get-PolicyString
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param ()

    Import-Module -Name ProcessMitigations -Verbose:0
    return [Microsoft.Samples.PowerShell.Commands.AppMitigations].GetProperties().Name
}

Export-ModuleMember -Function *-TargetResource
