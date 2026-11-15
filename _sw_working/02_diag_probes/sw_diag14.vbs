' sw_diag14.vbs - open diag13 gear, front view, verify gap cut, count faces
Option Explicit
Dim fso, lf, swApp, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag14.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & " " & Err.Description & "]"
  Err.Clear
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
L "SW attached"
swApp.CloseAllDocuments True
L "closed docs"
Dim errs, warns
Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_diag13_gear.SLDPRT", 1)
WScript.Sleep 800
L "opened part type=" & TypeName(md)
If Not md Is Nothing Then
  Dim bodies, nb
  bodies = md.GetBodies2(0, True)
  If IsArray(bodies) Then
    nb = UBound(bodies) + 1
    L "bodies=" & nb
    Dim b0, faces
    Set b0 = bodies(0)
    faces = b0.GetFaces
    If IsArray(faces) Then L "faces=" & (UBound(faces) + 1)
  End If
  md.ShowNamedView2 "*Front", 7
  WScript.Sleep 800
  md.SaveBMP "C:\Users\zgzgd\Documents\DSH\sw_shots\diag14_gear_front.bmp", 0, 0
  L "saved front bmp"
  md.ShowNamedView2 "*Isometric", 7
  WScript.Sleep 800
  md.SaveBMP "C:\Users\zgzgd\Documents\DSH\sw_shots\diag14_gear_iso.bmp", 0, 0
  L "saved iso bmp"
End If
L "DONE"
lf.Close
WScript.Quit
