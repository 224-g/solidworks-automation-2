Option Explicit
On Error Resume Next
Dim swApp, fso, lf, md
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag64.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s
End Sub
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then L "attach FAILED err=" & Err.Number : lf.Close : WScript.Quit
L "SW attached rev=" & swApp.RevisionNumber

Dim pi
pi = 4*Atn(1)

Sub NewPart()
  On Error Resume Next
  L "np-close1"
  swApp.CloseAllDocuments True
  L "np-close2 err=" & Err.Number
  Dim ok
  ok = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  L "np-newdoc err=" & Err.Number
  WScript.Sleep 600
  Set md = swApp.ActiveDoc
  If md Is Nothing Then L "NewPart FAILED" : Exit Sub
  L "newdoc ok"
End Sub

Sub PlaneSel(tag)
  swApp.ActiveDoc.ClearSelection2 True
  Dim b
  b = swApp.ActiveDoc.Extension.SelectByID2("", "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag & " planesel res=" & b & " err=" & Err.Number
End Sub

Sub SelSk(tag)
  Dim f
  Set f = md.FirstFeature
  Dim nm
  nm = ""
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then nm = f.Name
    Set f = f.GetNextFeature
  Loop
  If nm = "" Then L tag & " selsk NO-SKETCH" : Exit Sub
  Dim b
  b = md.Extension.SelectByID2(nm, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  L tag & " selsk name=" & nm & " res=" & b
End Sub

Function Extr(tag, d)
  md.SketchManager.InsertSketch True
  SelSk tag
  Dim ft
  Set ft = md.FeatureManager.FeatureExtrusion2(True, False, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L "ERR " & tag & " extrude NOTHING err=" & Err.Number
    Extr = False
  Else
    L "OK " & tag & " extrude name=" & ft.Name
    Extr = True
  End If
End Function

Sub Circ(x, y, r)
  md.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub

Sub Arc2(xs, ys, xe, ye, dirn)
  md.SketchManager.CreateArc 0, 0, 0, xs, ys, 0, xe, ye, 0, dirn
End Sub

Sub Line2(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub

Sub EqSpline(tag, xe, ye, r0, r1)
  md.SketchManager.CreateEquationSpline2 xe, ye, "0", r0, r1, False, 0, 0, 0, True, True
  L tag & " eqspline err=" & Err.Number
End Sub

' z40 constants
Dim rb, ra, rf, invp, inva, htp, ua, psRb, psLb, psRa, psLa
rb = 0.0375877
ra = 0.042
rf = 0.0375
invp = Tan(20*pi/180) - 20*pi/180
ua = Atn(Sqr((ra/rb)^2 - 1))
inva = ua - Atn(ua)
htp = pi/(2*40)
psRb = htp + invp
psLb = -psRb
psRa = psRb - inva
psLa = -psRa

Sub RingAnnu()
  Circ 0, 0, ra
  Circ 0, 0, 0.008
End Sub

' tooth with equation-spline flanks; root arc at rb, tip arc at ra
Sub ToothEq(tag)
  Dim xer, yer, xel, yel
  xer = "(0.03753254)*(cos(t)+t*sin(t))+(0.00203528)*(sin(t)-t*cos(t))"
  yer = "(0.00203528)*(cos(t)+t*sin(t))-(0.03753254)*(sin(t)-t*cos(t))"
  xel = "(0.03753254)*(cos(0.49830-t)+(0.49830-t)*sin(0.49830-t))+(0.00203528)*(sin(0.49830-t)-(0.49830-t)*cos(0.49830-t))"
  yel = "(-0.00203528)*(cos(0.49830-t)+(0.49830-t)*sin(0.49830-t))+(0.03753254)*(sin(0.49830-t)-(0.49830-t)*cos(0.49830-t))"
  ' root arc left->right CCW at rb
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  L tag & " after-rootarc err=" & Err.Number
  ' right flank base->tip
  EqSpline tag & "-right", xer, yer, "0", "0.49830"
  ' tip arc right->left CW
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  L tag & " after-tiparc err=" & Err.Number
  ' left flank tip->base
  EqSpline tag & "-left", xel, yel, "0", "0.49830"
End Sub

' tooth with 8-line flank polylines, root arc at rb (diag63-V2 repro)
Sub ToothLines(tag)
  Dim u, rr, an, i, pu, pv
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  pu = rb*Cos(psRb) : pv = rb*Sin(psRb)
  For i = 1 To 8
    u = ua*i/8
    rr = rb*Sqr(1+u*u)
    an = psRb - (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  pu = ra*Cos(psLa) : pv = ra*Sin(psLa)
  For i = 7 To 0 Step -1
    u = ua*i/8
    rr = rb*Sqr(1+u*u)
    an = psLb + (u - Atn(u))
    Line2 pu, pv, rr*Cos(an), rr*Sin(an)
    pu = rr*Cos(an) : pv = rr*Sin(an)
  Next
  L tag & " toothlines done err=" & Err.Number
End Sub

' tooth with 2 straight flank chords
Sub ToothChords(tag)
  Arc2 rb*Cos(psLb), rb*Sin(psLb), rb*Cos(psRb), rb*Sin(psRb), 1
  Line2 rb*Cos(psRb), rb*Sin(psRb), ra*Cos(psRa), ra*Sin(psRa)
  Arc2 ra*Cos(psRa), ra*Sin(psRa), ra*Cos(psLa), ra*Sin(psLa), -1
  Line2 ra*Cos(psLa), ra*Sin(psLa), rb*Cos(psLb), rb*Sin(psLb)
End Sub

Sub SaveIt(fn)
  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\" & fn & ".SLDPRT", 0, 2)
  L fn & " save res=" & res & " err=" & Err.Number
End Sub

' ============ cases ============
Sub CaseA()
  L "--- A equation flanks, with ring"
  NewPart
  PlaneSel "A"
  RingAnnu
  ToothEq "A"
  Extr "A", 0.018
  SaveIt "sw_diag64_A"
End Sub

Sub CaseB()
  L "--- B line flanks, with ring (V2 repro)"
  NewPart
  PlaneSel "B"
  RingAnnu
  ToothLines "B"
  Extr "B", 0.018
  SaveIt "sw_diag64_B"
End Sub

Sub CaseC()
  L "--- C 2-line chord flanks, with ring"
  NewPart
  PlaneSel "C"
  RingAnnu
  ToothChords "C"
  Extr "C", 0.018
  SaveIt "sw_diag64_C"
End Sub

Sub CaseD()
  L "--- D equation flanks, tooth alone (no ring)"
  NewPart
  PlaneSel "D"
  ToothEq "D"
  Extr "D", 0.018
  SaveIt "sw_diag64_D"
End Sub

CaseA
CaseB
CaseC
CaseD
L "=== diag64 ALL DONE"
lf.Close
