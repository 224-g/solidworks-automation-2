Stop-Process -Name sldworks, sldProcMon, sldworks_fs -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 1500
$out = "C:\Users\zgzgd\Documents\DSH\sw_kill_log.txt"
$remaining = Get-Process -Name sldworks -ErrorAction SilentlyContinue
if ($remaining) { Set-Content -Path $out -Value "STILL RUNNING" } else { Set-Content -Path $out -Value "KILLED OK" }