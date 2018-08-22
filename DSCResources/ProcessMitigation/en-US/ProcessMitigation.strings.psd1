ConvertFrom-StringData @'
    policyNotInDesiredStateEnabled  = {0} is not the desired state Current: Disabled Desired: Enabled
    policyNotInDesiredStateDisabled = {0} is not the desired state Current: Enabled Desired: Disabled
    setOnSystem                     = Running Set-ProcessMitigation on SYSTEM
    setOnProcess                    = Running Set-ProcessMitigation on process {0}
    getOnSystem                     = Running Get-ProcessMitigation on SYSTEM
    getOnProcess                    = Running Get-ProcessMitigation on process {0}
'@
