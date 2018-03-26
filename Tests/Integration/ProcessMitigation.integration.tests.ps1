
$script:DSCModuleName = 'ProcessMitigationDsc'
$script:DSCResourceName = 'ProcessMitigation'

#region HEADER
# Integration Test Template Version: 1.2.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should Not Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should Not Throw
        }
        #endregion

        $currentProcessMitgation = Get-DscConfiguration
        It 'Should have set the resource and all the parameters should match' {
            foreach ( $key in $processMitgationParameters.Keys )
            {
                $processMitgationParameters.$key | Should Be $currentProcessMitgation.$key
            }
        }
    }
    #endregion

}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
