' sw_diag42.vbs - probe saved gear faces + reproduce build gap-cut sequence
Option Explicit
Dim swApp, lf, FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
Set lf = FSO.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag42.log", True)

Sub L(tag, extra)
  On Error Resume Next
  lf.WriteLine Time & " " & tag & " " & extra & " [err=" & Err.Number & "]"
  If Err.Number <> 0 Then Err.Clear
End Sub

Sub ProbeFaces()
  Dim md
  Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_parts5\" & ChrW(&H4E3B) & ChrW(&H52A8) & ChrW(&H9F7F) & ChrW(&H8F6E) & ".SLDPRT", 1)
  If md Is Nothing Then
    L "P open", "FAILED"
    Exit Sub
  End If
  WScript.Sleep 300
  Dim pts(4, 2), i, selok, sf, bx, t
  pts(0, 0) = 0    : pts(0, 1) = 0.005 : pts(0, 2) = 0
  pts(1, 0) = 0    : pts(1, 1) = 0.005 : pts(1, 2) = 0.006
  pts(2, 0) = 0    : pts(2, 1) = 0.02  : pts(2, 2) = 0.018
  pts(3, 0) = 0    : pts(3, 1) = 0.005 : pts(3, 2) = 0.024
  pts(4, 0) = 0    : pts(4, 1) = 0.02  : pts(4, 2) = 0.024
  For i = 0 To 4
    md.ClearSelection2 True
    selok = md.Extension.SelectByID2("", "FACE", pts(i, 0), pts(i, 1), pts(i, 2), False, 0, Nothing, 0)
    If selok Then
      Set sf = md.SelectionManager.GetSelectedObject6(1, -1)
      bx = sf.GetBox
      L "P face" & i, "(" & pts(i, 0) & "," & pts(i, 1) & "," & pts(i, 2) & ") box=" & TypeName(bx) & " " & Join(bx, ",")
    Else
      L "P face" & i, "(" & pts(i, 0) & "," & pts(i, 1) & "," & pts(i, 2) & ") sel=FALSE"
    End If
    Err.Clear
  Next
  md.CloseDoc CStr(md.GetTitle)
End Sub

Sub PlaneSelR()
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  md.Extension.SelectByID2 "", "PLANE", 0, 0, 0, False, 0, Nothing, 0
  md.SketchManager.InsertSketch False
End Sub

Sub FaceSketchR(x, y, z, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.ClearSelection2 True
  Dim selok : selok = md.Extension.SelectByID2("", "FACE", x, y, z, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag & " facesk", "sel=" & selok
End Sub

Sub SelSkR(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  Dim f : Set f = md.FirstFeature
  Dim last : Set last = Nothing
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then Set last = f
    Set f = f.GetNextFeature
  Loop
  Dim r
  If last Is Nothing Then
    L tag & " selsk", "NOT-FOUND"
  Else
    r = md.Extension.SelectByID2(last.Name, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
    L tag & " selsk", last.Name & " res=" & r
  End If
End Sub

Sub ExtrR(flip, d, tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  SelSkR tag
  Dim ft : Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then L "ERR " & tag, "extrude Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub CutTAR(tag)
  On Error Resume Next
  Dim md : Set md = swApp.ActiveDoc
  md.SketchManager.InsertSketch True
  Dim ft : Set ft = md.FeatureManager.FeatureCut4(True, True, False, 1, 0, 0.001, 0, False, False, False, False, 0, 0, False, False, False, False, False, False, False, False, False, False, 0, 0, False, False)
  If ft Is Nothing Then L "ERR " & tag, "cut Nothing" Else L "OK " & tag, ft.Name
End Sub

Sub LineR(x1, y1, x2, y2)
  On Error Resume Next
  swApp.ActiveDoc.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub

Sub CircleR(x, y, r)
  On Error Resume Next
  swApp.ActiveDoc.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub

Sub Gap0R(z, k, tag)
  On Error Resume Next
  Dim PI : PI = 4 * Atn(1)
  Dim m, al, rp, rb, ra, rf, invp, ua, inva, htp, phik, psRb, psRa, psLb, psLa
  m = 0.002 : al = 20 * PI / 180
  rp = m * z / 2 : rb = rp * Cos(al) : ra = rp + m : rf = rp - 1.25 * m
  invp = Tan(al) - al
  ua = Sqr((ra / rb) * (ra / rb) - 1)
  inva = ua - Atn(ua)
  htp = PI / (2 * z)
  phik = 2 * PI * k / z
  psRb = phik + htp + invp
  psRa = phik + htp + invp - inva
  psLb = phik + 3 * PI / (2 * z) - invp
  psLa = phik + 3 * PI / (2 * z) - invp + inva
  L tag, "ra=" & ra & " rb=" & rb & " rf=" & rf & " psRb=" & psRb
  Dim sk : Set sk = swApp.ActiveDoc.SketchManager
  Dim i, u, r, ang, pts(26), segs
  LineR rf * Cos(psRb), rf * Sin(psRb), rb * Cos(psRb), rb * Sin(psRb)
  segs = sk.GetSketchSegments
  L tag & " afterA", "segs=" & (UBound(segs) + 1)
  For i = 0 To 8
    u = ua * i / 8
    r = rb * Sqr(1 + u * u)
    ang = psRb - (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  segs = sk.GetSketchSegments
  L tag & " afterB", "segs=" & (UBound(segs) + 1)
  sk.CreateArc 0, 0, 0, ra * Cos(psRa), ra * Sin(psRa), 0, ra * Cos(psLa), ra * Sin(psLa), 0, 1
  segs = sk.GetSketchSegments
  L tag & " afterC", "segs=" & (UBound(segs) + 1)
  For i = 0 To 8
    u = ua * (8 - i) / 8
    r = rb * Sqr(1 + u * u)
    ang = psLb + (u - Atn(u))
    pts(3 * i) = r * Cos(ang) : pts(3 * i + 1) = r * Sin(ang) : pts(3 * i + 2) = 0
  Next
  sk.CreateSpline2 pts, True
  segs = sk.GetSketchSegments
  L tag & " afterD", "segs=" & (UBound(segs) + 1)
  LineR rb * Cos(psLb), rb * Sin(psLb), rf * Cos(psLb), rf * Sin(psLb)
  segs = sk.GetSketchSegments
  L tag & " afterE", "segs=" & (UBound(segs) + 1)
  sk.CreateArc 0, 0, 0, rf * Cos(psLb), rf * Sin(psLb), 0, rf * Cos(psRb), rf * Sin(psRb), 0, -1
  segs = sk.GetSketchSegments
  L tag & " afterF", "segs=" & (UBound(segs) + 1)
End Sub

Sub CaseR1(tag)
  ' hubback + ring + hubfront + ONE gap (exact build sequence, z40 k0)
  On Error Resume Next
  Dim md : Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
  WScript.Sleep 400
  PlaneSelR
  CircleR 0, 0, 0.008
  ExtrR False, 0.006, tag & "-hubback"
  FaceSketchR 0, 0.005, 0.006, tag
  CircleR 0, 0, 0.042
  ExtrR False, 0.012, tag & "-ring"
  FaceSketchR 0, 0.005, 0.018, tag
  CircleR 0, 0, 0.008
  ExtrR False, 0.006, tag & "-hubfront"
  FaceSketchR 0, 0.02, 0.018, tag
  Gap0R 40, 0, tag
  CutTAR tag & "-gap0"
  Dim res : res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag42_R1.SLDPRT", 0, 2)
  L tag & " save", "res=" & res
  md.CloseDoc CStr(md.GetTitle)
End Sub

On Error Resume Next
Dim t
t = Timer
Do While swApp Is Nothing And Timer - t < 120
  Set swApp = GetObject("", "SldWorks.Application")
  If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
  If swApp Is Nothing Then WScript.Sleep 2000
Loop
If swApp Is Nothing Then
  L "FATAL", "no SW"
  lf.Close
  WScript.Quit
End If
L "attached", "rev=" & swApp.RevisionNumber

ProbeFaces
CaseR1 "R1"

L "DONE", "diag42"
lf.Close
