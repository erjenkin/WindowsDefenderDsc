# WindowsDefenderDsc
A collection of DSC resources to manage security mitigations in Windows Defender Security Center

## How to Contribute

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **ProcessMitigation**: Configures process mitigation policies.

## ProcessMitigation
* **MitigationTarget**: Name of the process to apply mitigation settings to.
* **Enable**: Comma separated list of mitigations to enable.
* **Disable**: Comma separated list of mitigations to disable.

## Versions

### Unreleased

### 1.0.0.0

* Intiial release with the following resources:
    * ProcessMitigation
