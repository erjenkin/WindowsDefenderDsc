
configuration SYSTEM_MSFeedSync
{

    Import-DscResource -ModuleName ProcessMitigationDsc
    node localhost
    {
        ProcessMitigation SYSTEM
        {
            MitigationTarget = 'SYSTEM'
            Enable           = 'DEP', 'SEHOP'
            Disable          = 'TerminateOnError'
        }

        ProcessMitigation msfeedssync
        {
            MitigationTarget = 'msfeedssync.exe'
            Enable = 'CFG'
            Disable = 'StrictHandle'
        }
    }
}

SYSTEM_MSFeedSync -OutputPath 'C:\DSC'

Start-DscConfiguration -Path 'C:\DSC' -Wait -Force -Verbose
