$log = "C:\Users\zgzgd\Documents\DSH\sw_test_log.txt"
"START $(Get-Date -Format o)" | Out-File $log -Encoding utf8
try {
    $sw = New-Object -ComObject SldWorks.Application
    "COM OK" | Out-File $log -Append -Encoding utf8
    $sw.Visible = $true
    Start-Sleep -Seconds 10
    "RevisionNumber: $($sw.RevisionNumber)" | Out-File $log -Append -Encoding utf8
    "Version: $($sw.Version)" | Out-File $log -Append -Encoding utf8
    "Loaded: $($sw.CommandInProgress)" | Out-File $log -Append -Encoding utf8
} catch {
    "ERROR: $($_.Exception.Message)" | Out-File $log -Append -Encoding utf8
}
"END $(Get-Date -Format o)" | Out-File $log -Append -Encoding utf8
