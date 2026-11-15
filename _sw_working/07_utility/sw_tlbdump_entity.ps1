Add-Type -Path 'C:\Users\zgzgd\Documents\DSH\TlbDump.cs'
$tlb = 'D:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldworks.tlb'
$out = [TlbDump.Dump]::Run($tlb, 'IEntity', @())
[IO.File]::WriteAllText('C:\Users\zgzgd\Documents\DSH\tlb_entity.txt', $out, [Text.Encoding]::UTF8)
Write-Output $out.Substring(0, [Math]::Min(2500, $out.Length))
