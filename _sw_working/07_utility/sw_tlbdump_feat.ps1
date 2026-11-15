Add-Type -Path 'C:\Users\zgzgd\Documents\DSH\TlbDump.cs'
$tlb = 'D:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldworks.tlb'
$out1 = [TlbDump.Dump]::Run($tlb, 'IFeature', @('GetTypeName2','GetNextFeature','Select2','Select3','Name','GetTypeName'))
Write-Output '---IFeature---'
Write-Output $out1
$out2 = [TlbDump.Dump]::Run($tlb, 'IFace2', @('Select2','Select3','Select4','Select','GetBox'))
Write-Output '---IFace2---'
Write-Output $out2
