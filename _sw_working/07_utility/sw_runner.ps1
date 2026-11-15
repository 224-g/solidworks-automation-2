# Elevated command runner: executes one command per queue file
# Protocol: sw_queue.cmd (content = command) -> sw_queue_exit.txt (exit code) -> sw_queue_done.txt (marker)
# To stop the runner, enqueue exactly: EXIT
$dir = "C:\Users\zgzgd\Documents\DSH"
$queue = Join-Path $dir "sw_queue.cmd"
$exitf = Join-Path $dir "sw_queue_exit.txt"
$done  = Join-Path $dir "sw_queue_done.txt"
while ($true) {
  if (Test-Path $queue) {
    $cmd = (Get-Content $queue -Raw).Trim()
    Remove-Item $queue -Force
    Remove-Item $done -Force -ErrorAction SilentlyContinue
    if ($cmd -eq "EXIT") { Write-Output "runner exit requested"; exit 0 }
    $code = 0
    try {
      cmd /c $cmd
      $code = $LASTEXITCODE
    } catch {
      $code = -1
    }
    Set-Content -Path $exitf -Value $code
    Set-Content -Path $done -Value "done"
  }
  Start-Sleep -Milliseconds 500
}
