$dir = 'C:\Users\zgzgd\Documents\DSH\精英联赛_设计包\工程图'
$stop = 'C:\Users\zgzgd\Documents\DSH\sw_http_stop.txt'
if (Test-Path $stop) { Remove-Item $stop -Force }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://127.0.0.1:8099/')
$listener.Start()
Write-Output "serving $dir on http://127.0.0.1:8099/"
while (-not (Test-Path $stop)) {
  if (-not $listener.IsListening) { break }
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
  if ($path -eq '/') { $path = '/index.html' }
  $file = Join-Path $dir ($path.TrimStart('/'))
  if (Test-Path $file -PathType Leaf) {
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $ct = switch ($ext) { '.html' { 'text/html; charset=utf-8' } '.svg' { 'image/svg+xml; charset=utf-8' } default { 'application/octet-stream' } }
    $bytes = [IO.File]::ReadAllBytes($file)
    $res.ContentType = $ct
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
  }
  $res.Close()
}
$listener.Stop()
