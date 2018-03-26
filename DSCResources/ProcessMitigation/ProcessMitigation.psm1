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

    $returnValue = @{
        MitigationTarget = $MitigationTarget
        Enable           = ( $results | Where-Object -FilterScript { $PSItem.Value -eq 'ON' } ).Mitigation
        Disable          = ( $results | Where-Object -FilterScript { $PSItem.Value -eq 'OFF' } ).Mitigation
        Default          = ( $results | Where-Object -FilterScript { $PSItem.Value -eq 'NOTSET' } ).Mitigation
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
            Write-Verbose -Message "$policy is not the desired state Current: Disabled Desired: Enabled"
            $inDesiredState = $false
        }
    }

    # verify policies in Disable are in a desired state
    foreach ( $policy in $Disable )
    {
        if ( $policy -notin $currentState.Disable )
        {
            Write-Verbose -Message "$policy is not the desired state Current: Enabled Desired: Disabled"
            $inDesiredState = $false
        }
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
