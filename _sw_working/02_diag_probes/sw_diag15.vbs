' sw_diag15.vbs - verify gear cut via body face count + mass props
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag15.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & " " & Err.Description & "]"
  Err.Clear
End Sub
Sub InspectBody(tag)
  On Error Resume Next
  Dim mp
  Set mp = md.Extension.CreateMassProperty
  L tag & " mp type=" & TypeName(mp)
  If Not mp Is Nothing Then
    mp.UseSystemUnits = False
    L tag & " setunits done"
    Dim v
    v = mp.Volume
    L tag & " volume m3=" & v
    If IsNumeric(v) Then L tag & " volume mm3=" & Round(CDbl(v) * 1000000000, 1)
    Dim m
    m = mp.Mass
    L tag & " mass kg=" & m
  End If
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
L "closed docs"
Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag13_gear.SLDPRT", 1)
WScript.Sleep 800
L "opened type=" & TypeName(md)
If Not md Is Nothing Then InspectBody "GEAR"
L "DONE"
lf.Close
WScript.Quit
