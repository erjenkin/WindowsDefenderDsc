
#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ((-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
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


        $testParameters = @(
            @{
                MitigationTarget = "winword.exe"
                MitigationType = "DEP"
                MitigationName = "OverrideDEP"
                MitigationValue = "true"
            },
            @{
                MitigationTarget = "{0}_{1}" -f "DOESNTEXIST", (Get-Random)
                MitigationType = "DEP"
                MitigationName = "OverrideDEP"
                MitigationValue = "true"
            },
            @{
                MitigationTarget = "winword.exe"
                MitigationType = "DEP"
                MitigationName = "OverrideDEP"
                MitigationValue = "false"
            },
            @{
                MitigationTarget = "System"
                MitigationType = "DEP"
                MitigationName = "OverrideDEP"
                MitigationValue = "false"
            }
        )

        foreach ($parameterSet in $testParameters)
        {
            Describe 'Get-TargetResource'{
                Context 'Testing Get-TargetResource function' {
                    $result = Get-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue

                    It 'Should not throw'{
                        {Get-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue} | Should -Not -Throw
                    }

                    It 'Should return and xml'{
                    $result | Should -BeOfType System.Xml.XmlNode
                    }
                }
            }

            Describe 'Test-TargetResource'{
                Context 'Testing Test-TargetResource function' {
                    $result = Test-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue
                    if ($parameterSet.MitigationTarget -eq "System")
                    {
                        [string] $resultCurrent = (Get-ProcessMitigation -System).($parameterSet.MitigationType).($parameterSet.MitigationName)
                    }
                    else
                    {
                        [string] $resultCurrent = (Get-ProcessMitigation -Name $parameterSet.MitigationTarget).($parameterSet.MitigationType).($parameterSet.MitigationName)
                    }

                    if ($parameterSet.MitigationValue -eq $resultCurrent)
                    {
                        It 'Should return true'{
                            $result | Should -Be $true
                        }
                    }
                    else
                    {
                        It 'Should return false'{
                            $result | Should -Be $false
                        }
                    }

                    It 'Should not throw'{
                        {Test-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue} | Should -Not -Throw
                    }
                }
            }

            Describe 'Set-TargetResource'{
                Context 'Testing Set-TargetResource function' {

                    Set-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue
                    $result = Test-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue
                    $resultSet = (Get-ProcessMitigation -Name $parameterSet.MitigationTarget).($parameterSet.MitigationType).($parameterSet.MitigationName)
                    if ($parameterSet.MitigationValue -eq "false")
                    {
                        It "Should be equal to $($parameterSet.MitigationValue)"{
                            $resultSet | Should -be $false
                        }
                    }
                    else {
                        It "Should be equal to $($parameterSet.MitigationValue)"{
                            $resultSet | Should -be $true
                        }
                    }

                    It 'Should not throw'{
                        {Set-TargetResource -MitigationTarget $parameterSet.MitigationTarget -MitigationType $parameterSet.MitigationType -MitigationName $parameterSet.MitigationName -MitigationValue $parameterSet.MitigationValue} | Should -Not -Throw
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
