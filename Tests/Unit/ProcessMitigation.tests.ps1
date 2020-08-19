
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



#endregion HEADER


function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    InModuleScope 'ProcessMitigation' {

        Describe 'Get-CurrentProcessMitigation'{
            Context 'Getting current Process Mitigation Settings' {
                $currentProcessMitigationResult = Get-CurrentProcessMitigation

                It 'Should return 14 Mitigation types per target' {
                    $currentProcessMitigationResult[0].Values.Keys.Count | Should -Be 14
                }

                It 'Should return 14 Mitigation Names per target' {
                    $currentProcessMitigationResult[0].Values.Values.Count | Should -Be 14
                }

                It 'Should return type object array' {
                    $currentProcessMitigationResult.GetType().Name | Should -Be 'Object[]'
                }
            }
        }

        Describe 'Convert-CurrentMitigations'{
            Context 'Converting Values to True/False' {
                $currentProcessMitigationResult = Get-CurrentProcessMitigation
                $convertCurrentMitigationsResult = Convert-CurrentMitigations -CurrentMitigations $currentProcessMitigationResult

                It 'Should return only values of true or false' {
                    $convertCurrentMitigationsResult.values.values.values | Should -Contain 'false'
                    $convertCurrentMitigationsResult.values.values.values | Should -Contain 'true'
                }

                It 'Should not contain the values ON or OFF' {
                    $convertCurrentMitigationsResult.values.values.values -match 'ON' | Should -BeFalse
                    $convertCurrentMitigationsResult.values.values.values -match 'OFF'| Should -BeFalse
                }
            }
        }

        Describe 'Get-CurrentProcessMitigationXml'{
            Context 'Generating new XML from converted results' {
                $currentProcessMitigationResult = Get-CurrentProcessMitigation
                $convertCurrentMitigationsResult = Convert-CurrentMitigations -CurrentMitigations $currentProcessMitigationResult
                $CurrentProcessMitigationXml = Get-CurrentProcessMitigationXml -CurrentMitigationsConverted $convertCurrentMitigationsResult

                It 'Should return the path of the new xml'{
                    $CurrentProcessMitigationXml | Should -BeLike "*\AppData\Local\Temp\MitigationsCurrent.xml"
                }
            }
        }


        $testParameters = @{

            MitigationTarget = "winword.exe"
            MitigationType = "DEP"
            MitigationName = "OverrideDEP"
            MitigationValue = "false"
        }

        Describe 'Get-TargetResource'{
            Context 'Testing Get-TargetResource function' {
                $result = Get-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue

                It 'Should not throw'{
                    {Get-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue} | Should -Not -Throw
                }

                It 'Should return and xml'{
                   $result | Should -BeOfType System.Xml.XmlNode
                }
            }
        }

        Describe 'Test-TargetResource'{
            Context 'Testing Test-TargetResource function' {
                $result = Test-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue
                [string] $resultCurrent = (Get-ProcessMitigation -Name $testParameters.MitigationTarget).($testParameters.MitigationType).($testParameters.MitigationName)

                if($resultCurrent -eq $testParameters.MitigationValue)
                {
                    It 'Should return true'{
                        $result | Should -BeTrue
                    }
                }
                else
                {
                    It 'Should return false'{
                        $result | Should -Befalse
                    }
                }

                It 'Should not throw'{
                    {Test-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue} | Should -Not -Throw
                }
            }
        }

        Describe 'Set-TargetResource'{
            Context 'Testing Set-TargetResource function' {

                $result = Test-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue

                if ($result -eq $false)
                {
                    Set-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue
                    $resultSet = (Get-ProcessMitigation -Name $testParameters.MitigationTarget).($testParameters.MitigationType).($testParameters.MitigationName)

                    It 'Should be equal to $testParameters.MitigationValue'{
                        $resultSet | Should -be "OFF"
                    }
                }
                else
                {
                    It 'Should not throw'{
                        {Set-TargetResource -MitigationTarget $testParameters.MitigationTarget -MitigationType $testParameters.MitigationType -MitigationName $testParameters.MitigationName -MitigationValue $testParameters.MitigationValue} | Should -Not -Throw
                    }
                }
            }
        }
    }
}








<#
        Describe 'Get-TargetResource' {
            Context 'MitigationTarget is System' {

                Mock -CommandName Get-ProcessMitigation -MockWith { $getProcessMitigationMock }
                Mock -CommandName Get-PolicyString -MockWith { $mockPolicyStrings }
                $result = Get-TargetResource -MitigationTarget SYSTEM -Enable TerminateOnError -Disable SEHOP, BlockRemoteImageLoads

                It 'Should return expected values for Enabled' {
                    $result.Enable | Should -Be 'TerminateOnError'
                }

                It 'Should return expected values for Disabled' {
                    $result.Disable | Should -Be 'SEHOP'
                }

                It 'Should return expected values for Default' {
                    $result.Default | Should -Be 'BlockRemoteImageLoads'
                }
            }

            Context 'MitigationTarget is not System' {
                Mock -CommandName Get-ProcessMitigation -MockWith { $getProcessMitigationMock }
                Mock -CommandName Get-PolicyString -MockWith { $mockPolicyStrings }
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
                Mock -CommandName Get-PolicyString -MockWith { $mockPolicyStrings }
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
                Mock -CommandName Get-PolicyString -MockWith { $mockPolicyStrings }

                It 'Enable Should be NULL' {
                    $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BlockRemoteImageLoads
                    [string]::IsNullOrWhiteSpace($result.Enable) | Should Be $true
                }

                It 'Disable Should be NULL' {
                    $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BlockRemoteImageLoads
                    [string]::IsNullOrWhiteSpace($result.Disable) | Should Be $true
                }

                It 'Default Should be NULL' {
                    $result = Get-TargetResource -MitigationTarget SYSTEM -Enable BottomUp
                    [string]::IsNullOrWhiteSpace($result.Default) | Should Be $true
                }
            }

            Context 'Return hashtable values should be array' {
                Mock -CommandName Get-ProcessMitigation -MockWith {$getProcessMitigationMock}
                Mock -CommandName Get-PolicyString -MockWith { $mockPolicyStrings }
                $result = Get-TargetResource -MitigationTarget 'notepad.exe' -Enable DEP -Disable BottomUp, BlockRemoteImageLoads

                It 'Should be an array' {
                    $result.Enable -is [array] | Should Be $true
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

            Context 'Not in a desired state' {
                It 'Should return FALSE when Enable is not in a desired state' {
                    $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP', 'TelemetryOnly'
                    $result | Should Be $false
                }

                It 'Should return FALSE when Disable is not in a desired state' {
                    $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP' -Disable 'TerminateOnError'
                    $result | Should Be $false
                }

                It 'Should return FALSE when policy is default' {
                    $result = Test-TargetResource -MitigationTarget SYSTEM -Enable 'DEP', 'BottomUp'
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
}#>
finally
{
    Invoke-TestCleanup
}
