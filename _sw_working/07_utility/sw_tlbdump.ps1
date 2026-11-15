param([string]$Iface = 'ISldWorks', [string]$Methods = '')
Add-Type -TypeDefinition ([IO.File]::ReadAllText('C:\Users\zgzgd\Documents\DSH\TlbDump.cs')) -ReferencedAssemblies System.Runtime.InteropServices
$names = @()
if ($Methods -ne '') { $names = $Methods.Split(',') }
[TlbDump.Dump]::Run('D:\Program Files\SOLIDWORKS Corp\SOLIDWORKS\sldworks.tlb', $Iface, $names)
