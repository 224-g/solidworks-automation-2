$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$t = Add-Type -MemberDefinition $sig -Name K32 -Namespace Win32 -PassThru
$ES = 0x80000003  # CONTINUOUS | DISPLAY_REQUIRED | SYSTEM_REQUIRED
while ($true) {
  [Win32.K32]::SetThreadExecutionState($ES) | Out-Null
  Start-Sleep -Seconds 60
}
