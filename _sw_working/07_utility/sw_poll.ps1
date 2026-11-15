$deadline = (Get-Date).AddSeconds(600)
$ok = $false
while ((Get-Date) -lt $deadline) {
  & cscript //nologo "C:\Users\zgzgd\Documents\DSH\sw_probe.vbs" | Out-Null
  $log = Get-Content "C:\Users\zgzgd\Documents\DSH\sw_probe.log" -Raw
  if ($log -match "SW attached") { $ok = $true; break }
  Start-Sleep -Seconds 10
}
Write-Output ("poll finished ok=" + $ok)
Get-Content "C:\Users\zgzgd\Documents\DSH\sw_probe.log"
