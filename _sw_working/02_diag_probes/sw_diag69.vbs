Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md, planeNames(2)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag69.log", True, True)
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
  If b = False Then L "PLANESEL FALSE!"
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
  If b = False Then L tag & " SELSK FALSE name=" & lastF.Name
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

Sub EqSpline(tag, xe, ye, r1)
  Err.Clear
  md.SketchManager.CreateEquationSpline2 xe, ye, "0", "0", r1, False, 0, 0, 0, True, True
  L "  " & tag & " eqspline err=" & Err.Number
End Sub

Sub SaveIt(fn)
  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L fn & " save res=" & res
End Sub

Sub Dloop(thf)
  Dim s, x1, y1, x2, y2
  s = Sqr(0.0051*0.0051 - 0.002*0.002)
  x1 = 0.002*Cos(thf) - s*Sin(thf)
  y1 = 0.002*Sin(thf) + s*Cos(thf)
  x2 = 0.002*Cos(thf) + s*Sin(thf)
  y2 = 0.002*Sin(thf) - s*Cos(thf)
  Arc2 x1, y1, x2, y2, 1
  md.SketchManager.CreateLine x2, y2, 0, x1, y1, 0
End Sub

' generic equation-spline tooth: root arc at rb + right EQ spline + tip arc + left EQ spline
' constants passed in: rb, ra, ua, psRb, psLb, psRa, psLa
Sub ToothEq(rb, ra, ua, psRb, psLb, psRa, psLa)
  Dim c1, s1, k1, k2, k3, k4, uas, xer, yer, xel, yel
  c1 = Cos(psRb)
  s1 = Sin(psRb)
  k1 = rb*c1
  k2 = rb*s1
  xer = "(" & CStr(k1) & ")*(cos(t)+t*sin(t))+(" & CStr(k2) & ")*(sin(t)-t*cos(t))"
  yer = "(" & CStr(k2) & ")*(cos(t)+t*sin(t))-(" & CStr(k1) & ")*(sin(t)-t*cos(t))"
  uas = CStr(ua)
  xel = "(" & CStr(k1) & ")*(cos(" & uas & "-t)+(" & uas & "-t)*sin(" & uas & "-t))+(" & CStr(k2) & ")*(sin(" & uas & "-t)-(" & uas & "-t)*cos(" & uas & "-t))"
  yel = "(-" & CStr(k2) & ")*(cos(" & uas & "-t)+(" & uas & "-t)*sin(" & uas & "-t))+(" & CStr(k1) & ")*(sin(" & uas & "-t)-(" & uas & "-t)*cos(" & uas & "-t))"
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  EqSpline "right", xer, yer, uas
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  EqSpline "left", xel, yel, uas
End Sub

' ---------- z40 constants ----------
Dim rb4, ra4, ua4, inva4, htp4, psRb4, psLb4, psRa4, psLa4, invp
invp = Tan(20*pi/180) - 20*pi/180
rb4 = 0.0375877
ra4 = 0.042
ua4 = Atn(Sqr((ra4/rb4)^2 - 1))
inva4 = ua4 - Atn(ua4)
htp4 = pi/80
psRb4 = htp4 + invp
psLb4 = -psRb4
psRa4 = psRb4 - inva4
psLa4 = -psRa4

' ---------- z20 constants ----------
Dim rb2, ra2, ua2, inva2, htp2, psRb2, psLb2, psRa2, psLa2
rb2 = 0.01879385
ra2 = 0.022
ua2 = Atn(Sqr((ra2/rb2)^2 - 1))
inva2 = ua2 - Atn(ua2)
htp2 = pi/40
psRb2 = htp2 + invp
psLb2 = -psRb2
psRa2 = psRb2 - inva2
psLa2 = -psRa2

' ---------- Case 1: z40 EQ tooth, separate sketch ----------
L "--- 1 z40 EQ tooth separate sketch"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 83.25*pi/180
Extr "1-hub", 0.024
PlaneSel
Circ 0, 0, ra4
Circ 0, 0, 0.008
Extr "1-ring", 0.018
PlaneSel
ToothEq rb4, ra4, ua4, psRb4, psLb4, psRa4, psLa4
CountSegs "1-tooth"
Extr "1-tooth", 0.018
SaveIt "sw_diag69_1"

' ---------- Case 2: z20 EQ tooth, separate sketch ----------
L "--- 2 z20 EQ tooth separate sketch"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 94.5*pi/180
Extr "2-hub", 0.024
PlaneSel
Circ 0, 0, ra2
Circ 0, 0, 0.008
Extr "2-ring", 0.018
PlaneSel
ToothEq rb2, ra2, ua2, psRb2, psLb2, psRa2, psLa2
CountSegs "2-tooth"
Extr "2-tooth", 0.018
SaveIt "sw_diag69_2"

L "=== diag69 ALL DONE"
lf.Close
