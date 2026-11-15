Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md, planeNames(2)
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag68.log", True, True)
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

' ---------- z40 ----------
Dim rb4, ra4, invp, htp4, ua4, inva4, psRb4, psLb4, psRa4, psLa4
rb4 = 0.0375877
ra4 = 0.042
invp = Tan(20*pi/180) - 20*pi/180
ua4 = Atn(Sqr((ra4/rb4)^2 - 1))
inva4 = ua4 - Atn(ua4)
htp4 = pi/80
psRb4 = htp4 + invp
psLb4 = -psRb4
psRa4 = psRb4 - inva4
psLa4 = -psRa4

' ---------- z20 ----------
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

' z40 tooth: root arc at rb + 8+4+8 lines (no radials)
Sub Tooth40()
  Dim i, u, rr, an, pu, pv
  Arc2 rb4*Cos(psLb4), rb4*Sin(psLb4), rb4*Cos(psRb4), rb4*Sin(psRb4), 1
  pu = rb4*Cos(psRb4) : pv = rb4*Sin(psRb4)
  For i = 1 To 8
    u = ua4*i/8
    rr = rb4*Sqr(1+u*u)
    an = psRb4 - (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  pu = ra4*Cos(psRa4) : pv = ra4*Sin(psRa4)
  For i = 1 To 4
    an = psRa4 + (psLa4 - psRa4)*i/4
    Line2 pu, pv, ra4*Cos(an), ra4*Sin(an)
    pu = ra4*Cos(an) : pv = ra4*Sin(an)
  Next
  pu = ra4*Cos(psLa4) : pv = ra4*Sin(psLa4)
  For i = 7 To 0 Step -1
    u = ua4*i/8
    rr = rb4*Sqr(1+u*u)
    an = psLb4 + (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
End Sub

' z20 tooth: full v7 loop (root arc at rf + radials + 8+4+8)
Sub Tooth20()
  Dim i, u, rr, an, pu, pv
  Arc2 rf2*Cos(psLb2), rf2*Sin(psLb2), rf2*Cos(psRb2), rf2*Sin(psRb2), 1
  Line2 rf2*Cos(psRb2), rf2*Sin(psRb2), rb2*Cos(psRb2), rb2*Sin(psRb2)
  pu = rb2*Cos(psRb2) : pv = rb2*Sin(psRb2)
  For i = 1 To 8
    u = ua2*i/8
    rr = rb2*Sqr(1+u*u)
    an = psRb2 - (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  pu = ra2*Cos(psRa2) : pv = ra2*Sin(psRa2)
  For i = 1 To 4
    an = psRa2 + (psLa2 - psRa2)*i/4
    Line2 pu, pv, ra2*Cos(an), ra2*Sin(an)
    pu = ra2*Cos(an) : pv = ra2*Sin(an)
  Next
  pu = ra2*Cos(psLa2) : pv = ra2*Sin(psLa2)
  For i = 7 To 0 Step -1
    u = ua2*i/8
    rr = rb2*Sqr(1+u*u)
    an = psLb2 + (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  Line2 rb2*Cos(psLb2), rb2*Sin(psLb2), rf2*Cos(psLb2), rf2*Sin(psLb2)
End Sub

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

' ---------- Case C: z40 root@rb no-radial tooth ----------
L "--- C z40 root@rb no-radial, named planes"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 83.25*pi/180
Extr "C-hub", 0.024
PlaneSel
Circ 0, 0, ra4
Circ 0, 0, 0.008
Extr "C-ring", 0.018
PlaneSel
Tooth40
CountSegs "C-tooth"
Extr "C-tooth", 0.018
SaveIt "sw_diag68_C"

' ---------- Case D: z20 full v7 loop regression ----------
L "--- D z20 full v7 loop, named planes"
NewPart
PlaneSel
Circ 0, 0, 0.008
Dloop 94.5*pi/180
Extr "D-hub", 0.024
PlaneSel
Circ 0, 0, ra2
Circ 0, 0, 0.008
Extr "D-ring", 0.018
PlaneSel
Tooth20
CountSegs "D-tooth"
Extr "D-tooth", 0.018
SaveIt "sw_diag68_D"

L "=== diag68 ALL DONE"
lf.Close
