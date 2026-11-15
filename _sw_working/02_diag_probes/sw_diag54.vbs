' sw_diag54.vbs - full gear1 via NESTED EXTRUDES only (no cuts)
' hub annulus via 2 CCW circles, filler rect, 5 tooth bosses (all-lines)
Option Explicit
On Error Resume Next
Dim swApp, md, sk, ft, part
Dim LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag54.log", 8, True)
Set lf = LOG
Sub L(tag, msg)
  lf.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Const PI = 3.14159265358979
Dim gPartTpl
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub NewPart(tag)
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  If md Is Nothing Then
    L tag & "-newdoc", "FAILED"
    Exit Sub
  End If
  WScript.Sleep 500
  L tag & "-newdoc", "ok"
End Sub

Sub PlaneSel(tag)
  md.ClearSelection2 True
  Dim b : b = md.Extension.SelectByID2("", "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag & "-plane", "sel=" & b
End Sub

Sub SelSk(tag)
  Dim f
  Set f = md.FirstFeature
  Dim last, lastN
  Set last = Nothing
  Do While Not f Is Nothing
    If f.GetTypeName2 = "ProfileFeature" Then
      Set last = f
      lastN = f.Name
    End If
    Set f = f.GetNextFeature
  Loop
  If last Is Nothing Then
    L tag & "-selsk", "NONE"
    Exit Sub
  End If
  Dim b : b = md.Extension.SelectByID2(lastN, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  L tag & "-selsk", lastN & " res=" & b
End Sub

Sub Extr(tag, flip, d)
  md.SketchManager.InsertSketch True
  SelSk tag
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L tag, "ERR Nothing"
  Else
    L tag, "OK " & ft.Name
  End If
End Sub

Sub Line(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub

Sub Arc2(x1, y1, x2, y2, dirn)
  md.SketchManager.CreateArc 0, 0, 0, x1, y1, 0, x2, y2, 0, dirn
End Sub

Sub CountSegs(tag)
  WScript.Sleep 400
  Dim segs, ub
  Set segs = md.SketchManager.ActiveSketch.GetSketchSegments
  ub = UBound(segs)
  L tag, "segs=" & (ub + 1)
End Sub

' tooth single-loop boss sketch on FRONT plane: all-lines incl. 4-seg tip polyline
' inner arc r=rf from a2 to a1, 2 radials, tip 4 lines at r=ra
Sub ToothLoop(z, k, ringR)
  Dim phik, rf, ra, a1, a2, i, ang
  phik = 2 * PI * k / z
  rf = 0.002 * z / 2 - 0.0025
  ra = 0.002 * z / 2 + 0.002
  ' gap half-angle at rf and ra (approx 0.29*pi/z each side)
  Dim g : g = 0.29 * PI / z
  a1 = phik - g
  a2 = phik + g
  ' inner arc rf from a1 to a2 CCW (CreateArc)
  Arc2 rf * Cos(a1), rf * Sin(a1), rf * Cos(a2), rf * Sin(a2), 1
  ' radial up from (rf,a2) to (ra,a2)
  Line rf * Cos(a2), rf * Sin(a2), ra * Cos(a2), ra * Sin(a2)
  ' tip polyline a2 -> a1 in 4 steps (decreasing angle)
  For i = 1 To 4
    ang = a2 + (a1 - a2) * i / 4
    Line ra * Cos(a2 + (a1 - a2) * (i - 1) / 4), ra * Sin(a2 + (a1 - a2) * (i - 1) / 4), ra * Cos(ang), ra * Sin(ang)
  Next
  ' radial down from (ra,a1) to (rf,a1) closes at arc start
  Line ra * Cos(a1), ra * Sin(a1), rf * Cos(a1), rf * Sin(a1)
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber

  swApp.CloseAllDocuments True
  NewPart "G"

  ' hub annulus: 2 CCW full circles
  PlaneSel "G-hub"
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0051
  CountSegs "G-hub"
  Extr "G-hub", False, 0.024

  ' filler rect rotated by thf=94.5deg (covers D-hole cap)
  Dim thf, cs, sn, x1, y1, x2, y2, x3, y3, x4, y4
  thf = 94.5 * PI / 180
  cs = Cos(thf) : sn = Sin(thf)
  x1 = 0.0052 * cs - 0.002 * sn : y1 = 0.0052 * sn + 0.002 * cs
  x2 = 0.0052 * cs - 0.0052 * sn : y2 = 0.0052 * sn + 0.0052 * cs
  x3 = -0.0052 * cs - 0.0052 * sn : y3 = -0.0052 * sn + 0.0052 * cs
  x4 = -0.0052 * cs - 0.002 * sn : y4 = -0.0052 * sn + 0.002 * cs
  PlaneSel "G-filler"
  Line x1, y1, x2, y2
  Line x2, y2, x3, y3
  Line x3, y3, x4, y4
  Line x4, y4, x1, y1
  CountSegs "G-filler"
  Extr "G-filler", False, 0.024

  ' 5 tooth bosses
  Dim k
  For k = 0 To 4
    PlaneSel "G-tooth" & k
    ToothLoop 20, k, 0.022
    CountSegs "G-tooth" & k
    Extr "G-tooth" & k, False, 0.018
  Next

  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag54_G.SLDPRT", 0, 2)
  L "save", "res=" & res
  Dim res2
  res2 = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag54_G.STL", 0, 2)
  L "stl", "res=" & res2
  swApp.CloseDoc "sw_diag54_G.SLDPRT"
  L "done", "diag54"
End Sub

Call Main
