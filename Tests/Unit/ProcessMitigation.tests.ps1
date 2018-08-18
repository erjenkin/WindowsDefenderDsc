
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
    -DSCModuleName 'WindowsDefenderDsc' `
    -DSCResourceName 'ProcessMitigation' `
    -TestType Unit

function Set-ProcessMitigation
{
    param
    (
        [switch]$System,
        [string]$Name
    )
}

function Get-ProcessMitigation {}
#endregion HEADER


function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{

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

            Mock -CommandName Get-ProcessMitigation -MockWith { $getProcessMitigationMock }
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
            Mock -CommandName Get-ProcessMitigation -MockWith { $getProcessMitigationMock }
            $result = Get-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP -Disable BottomUp, BlockRemoteImageLoads, SEHOP, EmulateAtlThunks, TerminateOnError

            It 'Should return expected values for Enabled' {
                ($result.Enable | Sort-Object) | Should be ('DEP', 'TerminateOnError' | Sort-Object)
            }
            
            It 'Should return expected values for Disabled' {
                ($result.Disable | Sort-Object) | Should be ('BottomUp', 'SEHOP' | Sort-Object)
            }
            
            It 'Should return expected values for Default' {
                ($result.Default | Sort-Object) | Should be ('EmulateAtlThunks', 'BlockRemoteImageLoads' | Sort-Object)
            }
        }

        Context 'Return hashtable should not have empty elements' {
            Mock -CommandName Get-ProcessMitigation

            It 'Enable Should be NULL' {
                $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BlockRemoteImageLoads
                $null -eq $result.Enable | Should Be $true
            }

            It 'Disable Should be NULL' {
                $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BlockRemoteImageLoads
                $null -eq $result.Disable | Should Be $true
            }

            It 'Default Should be NULL' {
                $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BottomUp
                $null -eq $result.Default | Should Be $true
            }
        }

        Context 'Return hashtable values should be array' {
            Mock -CommandName Get-ProcessMitigation -MockWith {$getProcessMitigationMock}
            $result = Get-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP -Disable BottomUp, BlockRemoteImageLoads

            It 'Should be an array' {
                $result.Enable  -is [array] | Should Be $true
                $result.Disable -is [array] | Should Be $true
                $result.Default -is [array] | Should Be $true
            }
        }
    }

    Describe 'Test-TargetResource' {
        $mockGetTargetResource = @{
            MitigationTarget = 'SYSTEM'
            Enable           = 'DEP', 'TerminateOnError'
            Disable          = 'BlockRemoteImageLoads'
            Default          = 'BottomUp', 'EmulateAtlThunks'
        }

        Mock -CommandName 'Get-TargetResource' -MockWith {$mockGetTargetResource}

        Context 'Not is a desired state' {
            It 'Should return FALSE when Enable is not in a desired state' {
                $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP', 'TelemetryOnly'
                $result | Should Be $false
            }

            It 'Should return FALSE when Disable is not in a desired state' {
                $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP' -Disable 'TerminateOnError'
                $result | Should Be $false
            }

            It 'Should return FALSE when policy is default' {
                $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP','BottomUp'
                $result | Should Be $false
            }
        }

        Context 'In a desired state' {
            It 'Should be TRUE when Enable is in a desired state' {
                $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP'
                $result | Should Be $true
            }

            It 'Should be TRUE when Disable is in a desired state' {
                $result = Test-TargetResource -MitigationTarget SYSTEM -Disable 'BlockRemoteImageLoads'
                $result | Should Be $true
            }
        }
    }

    Describe 'Set-TargetResource' {
        Context 'When MitigationTarget is SYSTEM' {
            Mock -CommandName 'Set-ProcessMitigation'
            Set-TargetResource -MitigationTarget SYSTEM -Enable DEP

            It 'Should Set SYSTEM' {
                Assert-MockCalled Set-ProcessMitigation -Times 1 -ParameterFilter { $System -eq $true }
            }
        }

        Context 'When MitigationTarget is not SYSTEM' {
            Mock -CommandName 'Set-ProcessMitigation'
            Set-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP

            It 'Should Set notepad' {
                Assert-MockCalled Set-ProcessMitigation -Times 1 -ParameterFilter { $Name -eq 'notepad.exe' }
            }
        }
    }

}
finally
{
    Invoke-TestCleanup
}
