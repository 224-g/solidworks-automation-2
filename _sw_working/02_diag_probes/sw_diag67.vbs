Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md, planeNames(2)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag67.log", True, True)
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

' ---------- z40 constants ----------
Dim rb, ra, rf, invp, htp, ua, inva, psRb, psLb, psRa, psLa
rb = 0.0375877
ra = 0.042
rf = 0.0375
invp = Tan(20*pi/180) - 20*pi/180
ua = Atn(Sqr((ra/rb)^2 - 1))
inva = ua - Atn(ua)
htp = pi/80
psRb = htp + invp
psLb = -psRb
psRa = psRb - inva
psLa = -psRa

' full 23-seg v7 tooth loop (root arc at rf + radials + 8-line flanks + 4-line tip)
Sub ToothFull()
  Dim i, u, rr, an, pu, pv
  Arc2 rf*Cos(psLb), rf*Sin(psLb), rf*Cos(psRb), rf*Sin(psRb), 1
  Line2 rf*Cos(psRb), rf*Sin(psRb), rb*Cos(psRb), rb*Sin(psRb)
  pu = rb*Cos(psRb) : pv = rb*Sin(psRb)
  For i = 1 To 8
    u = ua*i/8
    rr = rb*Sqr(1+u*u)
    an = psRb - (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  pu = ra*Cos(psRa) : pv = ra*Sin(psRa)
  For i = 1 To 4
    an = psRa + (psLa - psRa)*i/4
    Line2 pu, pv, ra*Cos(an), ra*Sin(an)
    pu = ra*Cos(an) : pv = ra*Sin(an)
  Next
  pu = ra*Cos(psLa) : pv = ra*Sin(psLa)
  For i = 7 To 0 Step -1
    u = ua*i/8
    rr = rb*Sqr(1+u*u)
    an = psLb + (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  Line2 rb*Cos(psLb), rb*Sin(psLb), rf*Cos(psLb), rf*Sin(psLb)
End Sub

' simple 4-seg tooth
Sub ToothSimple()
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  Line2 rb*Cos(psRb), rb*Sin(psRb), ra*Cos(psRa), ra*Sin(psRa)
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  Line2 ra*Cos(psLa), ra*Sin(psLa), rb*Cos(psLb), rb*Sin(psLb)
End Sub

' D-hole loop at thf (v7 DLoop)
Sub Dloop(thf)
  Dim s, x1, y1, x2, y2
  s = Sqr(0.0051*0.0051 - 0.002*0.002)
  x1 = 0.002*Cos(thf) - s*Sin(thf)
  y1 = 0.002*Sin(thf) + s*Cos(thf)
  x2 = 0.002*Cos(thf) + s*Sin(thf)
  y2 = 0.002*Sin(thf) - s*Cos(thf)
  Arc2 x1, y1, x2, y2, 1
  Line2 x2, y2, x1, y1
End Sub

' ---------- Case A: full v7 recipe z40 with NAMED planes ----------
L "--- A z40 full recipe, named planes"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 83.25*pi/180
CountSegs "A-hub"
Extr "A-hub", 0.024
PlaneSel
Circ 0, 0, ra
Circ 0, 0, 0.008
CountSegs "A-ring"
Extr "A-ring", 0.018
PlaneSel
ToothFull
CountSegs "A-tooth"
Extr "A-tooth", 0.018
SaveIt "sw_diag67_A"

' ---------- Case B: simple tooth, separate sketch ----------
L "--- B z40 simple tooth, separate sketch"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 83.25*pi/180
Extr "B-hub", 0.024
PlaneSel
Circ 0, 0, ra
Circ 0, 0, 0.008
Extr "B-ring", 0.018
PlaneSel
ToothSimple
CountSegs "B-tooth"
Extr "B-tooth", 0.018
SaveIt "sw_diag67_B"

L "=== diag67 ALL DONE"
lf.Close
