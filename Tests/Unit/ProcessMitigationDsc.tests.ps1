
#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'ProcessMitigationDsc' `
    -DSCResourceName 'ProcessMitigationDsc' `
    -TestType Unit

#endregion HEADER


function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    InModuleScope 'ProcessMitigationDsc' {
        $getProcessMitigationMock = @{
            Heap = @{
                TerminateOnError = 'ON'
            }
            SEHOP = @{
                Enable = 'OFF'
                BlockRemoteImageLoads = 'NOTSET'
            }
            DEP   = @{
                Enable           = 'ON'
                EmulateAtlThunks = 'NOTSET'
            }
            ASLR  = @{
                BottomUp = 'OFF'
            }
        }
        Describe 'Get-TargetResource' {
            Context 'MitigationTarget is System' {
                Mock -CommandName Get-ProcessMitigation -MockWith {$getProcessMitigationMock}
                $result = Get-TargetResource -MitigationTarget SYSTEM -Enable TerminateOnError -Disable SEHOP, BlockRemoteImageLoads

                It 'Should return expected values for Enabled' {
                    $result.Enable | Should be 'TerminateOnError'
                }

                It 'Should return expected values for Disabled' {
                    $result.Disable | Should Be 'SEHOP'
                }

                It 'Should return expected values for Default' {
                    $result.Default | Should Be 'BlockRemoteImageLoads'
                }
            }

            Context 'MitigationTarget is not System' {
                Mock -CommandName Get-ProcessMitigation -MockWith {$getProcessMitigationMock}
                $result = Get-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP -Disable BottomUp, BlockRemoteImageLoads
                It 'Should return expected values for Enabled' {
                    $result.Enable | Should be 'DEP'
                }
                It 'Should return expected values for Disabled' {
                    $result.Disable | Should Be 'BottomUp'
                }

                It 'Should return expected values for Default' {
                    $result.Default | Should Be 'BlockRemoteImageLoads'
                }
            }
            
            Context 'Test when multiple Mitigations are returned per property' {
                Mock -CommandName Get-ProcessMitigation -MockWith {$getProcessMitigationMock}
                $result = Get-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP -Disable BottomUp, BlockRemoteImageLoads, SEHOP, BlockRemoteImageLoads, TerminateOnError
                It 'Should return expected values for Enabled' {
                    $result.Enable | Should be 'TerminateOnError', 'DEP'
                }
                
                It 'Should return expected values for Disabled' {
                    $result.Disable | Should be 'SEHOP', 'BottomUp'
                }
                
                It 'Should return expected values for Default' {
                    $result.Default | Should be 'EmulateAtlThunks','BlockRemoteImageLoads'
                }
            }
        }

        Describe 'Test-TargetResource' {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }

        # TODO: add more Describe blocks as needed
    }
}
finally
{
    Invoke-TestCleanup
}