Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md, planeNames(2)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag66.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s
End Sub
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then L "attach FAILED err=" & Err.Number : lf.Close : WScript.Quit
L "SW attached rev=" & swApp.RevisionNumber

Dim pi
pi = 4*Atn(1)

Sub GetPlanes()
  Dim f, n
  n = 0
  Set f = md.FirstFeature
  Do While Not f Is Nothing
    If f.GetTypeName2 = "RefPlane" And n < 3 Then
      planeNames(n) = f.Name
      n = n + 1
    End If
    Set f = f.GetNextFeature
  Loop
End Sub

Sub NewPart()
  On Error Resume Next
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  If md Is Nothing Then L "newdoc FAILED" : Exit Sub
  WScript.Sleep 400
  GetPlanes
End Sub

Sub PlaneSel()
  On Error Resume Next
  md.ClearSelection2 True
  Dim b
  b = md.Extension.SelectByID2(planeNames(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L "planesel res=" & b & " err=" & Err.Number
End Sub

Sub SelSk(tag)
  Dim f2, lastF
  Set f2 = md.FirstFeature
  Set lastF = Nothing
  Do While Not f2 Is Nothing
    If f2.GetTypeName2 = "ProfileFeature" Then Set lastF = f2
    Set f2 = f2.GetNextFeature
  Loop
  If lastF Is Nothing Then L tag & " selsk none" : Exit Sub
  Dim b
  b = md.Extension.SelectByID2(lastF.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  L tag & " selsk " & lastF.Name & " res=" & b
End Sub

Function Extr(tag, d)
  On Error Resume Next
  md.SketchManager.InsertSketch True
  SelSk tag
  Dim ft
  Set ft = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L "ERR " & tag & " NOTHING err=" & Err.Number
    Extr = False
  Else
    L "OK " & tag & " " & ft.Name
    Extr = True
  End If
End Function

Sub CountSegs(tag)
  Dim segs, n
  segs = md.SketchManager.ActiveSketch.GetSketchSegments
  If IsArray(segs) Then
    n = UBound(segs) + 1
    L tag & " segs=" & n
  Else
    L tag & " segs NOT-ARRAY err=" & Err.Number
  End If
End Sub

Sub Circ(x, y, r)
  Err.Clear
  md.SketchManager.CreateCircleByRadius x, y, 0, r
  If Err.Number <> 0 Then L "  circ ERR " & Err.Number
End Sub

Sub Arc2(xs, ys, xe, ye, dirn)
  Err.Clear
  md.SketchManager.CreateArc 0, 0, 0, xs, ys, 0, xe, ye, 0, dirn
  If Err.Number <> 0 Then L "  arc ERR " & Err.Number
End Sub

Sub Line2(x1, y1, x2, y2)
  Err.Clear
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
  If Err.Number <> 0 Then L "  line ERR " & Err.Number
End Sub

Sub SaveIt(fn)
  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L fn & " save res=" & res
End Sub

' z20 constants
Dim rb, ra, rf, invp, htp, ua, inva, psRb, psLb, psRa, psLa
rb = 0.01879385
ra = 0.022
rf = 0.0175
invp = Tan(20*pi/180) - 20*pi/180
ua = Atn(Sqr((ra/rb)^2 - 1))
inva = ua - Atn(ua)
htp = pi/40
psRb = htp + invp
psLb = -psRb
psRa = psRb - inva
psLa = -psRa

Sub Tooth()
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  Line2 rb*Cos(psRb), rb*Sin(psRb), ra*Cos(psRa), ra*Sin(psRa)
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  Line2 ra*Cos(psLa), ra*Sin(psLa), rb*Cos(psLb), rb*Sin(psLb)
End Sub

Sub Dloop()
  Arc2 0.002, 0.0051, 0.002, -0.0051, 1
  Line2 0.002, -0.0051, 0.002, 0.0051
End Sub

' Case 1: tooth alone
L "--- 1 tooth alone"
NewPart
PlaneSel
Tooth
CountSegs "1"
Extr "1-tooth-alone", 0.018
SaveIt "sw_diag66_1"

' Case 2: ring annulus alone (2 circles)
L "--- 2 ring annulus alone"
NewPart
PlaneSel
Circ 0, 0, ra
Circ 0, 0, 0.008
CountSegs "2"
Extr "2-ring", 0.018
SaveIt "sw_diag66_2"

' Case 3: ring OUTER circle + tooth (2 contours)
L "--- 3 ring outer + tooth"
NewPart
PlaneSel
Circ 0, 0, ra
Tooth
CountSegs "3"
Extr "3-ringouter-tooth", 0.018
SaveIt "sw_diag66_3"

' Case 4: ring annulus + tooth (3 contours)
L "--- 4 ring annulus + tooth"
NewPart
PlaneSel
Circ 0, 0, ra
Circ 0, 0, 0.008
Tooth
CountSegs "4"
Extr "4-ringannu-tooth", 0.018
SaveIt "sw_diag66_4"

' Case 5: D-shaft control (proven OK)
L "--- 5 dshaft control"
NewPart
PlaneSel
Arc2 0.002, 0.0051, 0.002, -0.0051, 1
Line2 0.002, -0.0051, 0.002, 0.0051
CountSegs "5"
Extr "5-dshaft", 0.018
SaveIt "sw_diag66_5"

' Case 6: ring outer + D-loop (2 contours, control)
L "--- 6 ring outer + dloop"
NewPart
PlaneSel
Circ 0, 0, ra
Dloop
CountSegs "6"
Extr "6-ring-dloop", 0.018
SaveIt "sw_diag66_6"

L "=== diag66 ALL DONE"
lf.Close
