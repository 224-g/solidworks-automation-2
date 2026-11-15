Add-Type -Path 'C:\Users\zgzgd\Documents\DSH\TlbDump.cs'
[TlbDump.Dump]::Run('D:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldworks.tlb', 'IFeatureManager', @('FeatureExtrusion2','FeatureCut4','FeatureRevolve2'))
