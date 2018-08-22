# WindowsDefenderDsc

A collection of DSC resources to manage security mitigations in Windows Defender Security Center

## How to Contribute

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **ProcessMitigation**: Leverages the ProcessMitigations module in (Windows 10 v1709 and newer) to manage process mitigation policies.

## ProcessMitigation

* **MitigationTarget**: Name of the process to apply mitigation settings to.
* **Enable**: List of mitigations to enable.
* **Disable**: List of mitigations to disable.

## Versions

### Unreleased

### 1.0.0.0

* Intiial release with the following resources:
  * ProcessMitigation

## Examples

### Enable/Disable process mitigations on SYSTEM and msfeedsync.exe

In the following example configuration, the DEP and SEHOP process mitigations are enabled while disabling TermindateOnError.
Additionally, the CFG process mitigation is enabled while StictHandle is disabled.

```PowerShell
configuration SYSTEM_MSFeedSync
{

    Import-DscResource -ModuleName WindowsDefenderDsc
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
```
