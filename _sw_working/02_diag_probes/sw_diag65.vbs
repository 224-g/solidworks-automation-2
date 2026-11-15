Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md, planeNames(2)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag65.log", True, True)
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
  L "planes: 0=" & planeNames(0) & " 1=" & planeNames(1) & " 2=" & planeNames(2)
End Sub

Sub NewPart()
  On Error Resume Next
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  If md Is Nothing Then L "newdoc FAILED" : Exit Sub
  WScript.Sleep 400
  L "newdoc ok"
  GetPlanes
End Sub

Sub PlaneSel()
  On Error Resume Next
  md.ClearSelection2 True
  Dim b
  b = md.Extension.SelectByID2(planeNames(0), "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  Err.Clear
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

Sub EqSpline(tag, xe, ye)
  Err.Clear
  md.SketchManager.CreateEquationSpline2 xe, ye, "0", "0", "0.49830", False, 0, 0, 0, True, True
  L "  " & tag & " eqspline err=" & Err.Number
End Sub

Sub SaveIt(fn)
  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L fn & " save res=" & res
End Sub

' ---------- z40 constants ----------
Dim rb4, ra4, rf4, invp, inva, htp4, ua4, psRb4, psLb4, psRa4, psLa4
rb4 = 0.0375877
ra4 = 0.042
rf4 = 0.0375
invp = Tan(20*pi/180) - 20*pi/180
ua4 = Atn(Sqr((ra4/rb4)^2 - 1))
inva = ua4 - Atn(ua4)
htp4 = pi/80
psRb4 = htp4 + invp
psLb4 = -psRb4
psRa4 = psRb4 - inva
psLa4 = -psRa4

' ---------- z20 constants ----------
Dim rb2, ra2, rf2, htp2, ua2, inva2, psRb2, psLb2, psRa2, psLa2
rb2 = 0.01879385
ra2 = 0.022
rf2 = 0.0175
htp2 = pi/40
ua2 = Atn(Sqr((ra2/rb2)^2 - 1))
inva2 = ua2 - Atn(ua2)
psRb2 = htp2 + invp
psLb2 = -psRb2
psRa2 = psRb2 - inva2
psLa2 = -psRa2

' tooth loop builder: root arc at rb, straight chords to tip arc at ra
Sub ToothSimple(rb, ra, psRb, psLb, psRa, psLa)
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  Line2 rb*Cos(psRb), rb*Sin(psRb), ra*Cos(psRa), ra*Sin(psRa)
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  Line2 ra*Cos(psLa), ra*Sin(psLa), rb*Cos(psLb), rb*Sin(psLb)
End Sub

Sub CaseZ40()
  L "--- Z40 simple tooth + ring annulus"
  NewPart
  PlaneSel
  Circ 0, 0, ra4
  Circ 0, 0, 0.008
  ToothSimple rb4, ra4, psRb4, psLb4, psRa4, psLa4
  CountSegs "Z40"
  Extr "Z40", 0.018
  SaveIt "sw_diag65_Z40"
End Sub

Sub CaseZ20()
  L "--- Z20 simple tooth + ring annulus"
  NewPart
  PlaneSel
  Circ 0, 0, ra2
  Circ 0, 0, 0.008
  ToothSimple rb2, ra2, psRb2, psLb2, psRa2, psLa2
  CountSegs "Z20"
  Extr "Z20", 0.018
  SaveIt "sw_diag65_Z20"
End Sub

Sub CaseEq()
  L "--- Z40 equation-spline tooth + ring annulus"
  NewPart
  PlaneSel
  Circ 0, 0, ra4
  Circ 0, 0, 0.008
  Arc2 rb4*Cos(psLb4), rb4*Sin(psLb4), rb4*Cos(psRb4), rb4*Sin(psRb4), 1
  EqSpline "right", "(0.03753254)*(cos(t)+t*sin(t))+(0.00203528)*(sin(t)-t*cos(t))", "(0.00203528)*(cos(t)+t*sin(t))-(0.03753254)*(sin(t)-t*cos(t))"
  Arc2 ra4*Cos(psRa4), ra4*Sin(psRa4), ra4*Cos(psLa4), ra4*Sin(psLa4), -1
  EqSpline "left", "(0.03753254)*(cos(0.49830-t)+(0.49830-t)*sin(0.49830-t))+(0.00203528)*(sin(0.49830-t)-(0.49830-t)*cos(0.49830-t))", "(-0.00203528)*(cos(0.49830-t)+(0.49830-t)*sin(0.49830-t))+(0.03753254)*(sin(0.49830-t)-(0.49830-t)*cos(0.49830-t))"
  CountSegs "EQ"
  Extr "EQ", 0.018
  SaveIt "sw_diag65_EQ"
End Sub

CaseZ40
CaseZ20
CaseEq
L "=== diag65 ALL DONE"
lf.Close
