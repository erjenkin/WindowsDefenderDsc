# Integration Test Config Template Version: 1.0.0

$processMitgationParameters = @{
    MitigationTarget = 'SYSTEM'
    Enable           = 'DEP','SEHOP'
    Disable          = 'ForceRelocateImages'
}

configuration ProcessMitigation_config {

    Import-DscResource -ModuleName 'WindowsDefenderDsc'

    node localhost {
        ProcessMitigation Integration_Test
        {
            MitigationTarget = $processMitgationParameters.MitigationTarget
            Enable           = $processMitgationParameters.Enable
            Disable          = $processMitgationParameters.Disable
        }
    }
}
