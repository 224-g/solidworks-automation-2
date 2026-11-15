Add-Type -Path "C:\Users\zgzgd\Documents\DSH\TlbDump.cs"
$out = [TlbDump.Dump]::Run("D:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldworks.tlb", "IFeatureManager", @())
Set-Content "C:\Users\zgzgd\Documents\DSH\tlb_featmgr.txt" $out -Encoding UTF8
Write-Output "dumped: $($out.Length) chars"
