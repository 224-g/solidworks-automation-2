' sw_diag55.vbs - gear1 with RING annulus connecting teeth to hub (no cuts, all nested extrudes)
' hub annulus d24 + filler d24 + ring annulus (ra/8) d18 + 5 teeth d18
Option Explicit
Dim swApp, md, ft
Dim LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag55.log", 8, True)
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

' tooth boss: inner arc rf a1->a2 CCW + radials + 4-seg tip polyline
Sub ToothLoop(z, k)
  Dim phik, rf, ra, a1, a2, i, ang
  phik = 2 * PI * k / z
  rf = 0.002 * z / 2 - 0.0025
  ra = 0.002 * z / 2 + 0.002
  Dim g : g = 0.29 * PI / z
  a1 = phik - g
  a2 = phik + g
  Arc2 rf * Cos(a1), rf * Sin(a1), rf * Cos(a2), rf * Sin(a2), 1
  Line rf * Cos(a2), rf * Sin(a2), ra * Cos(a2), ra * Sin(a2)
  For i = 1 To 4
    ang = a2 + (a1 - a2) * i / 4
    Line ra * Cos(a2 + (a1 - a2) * (i - 1) / 4), ra * Sin(a2 + (a1 - a2) * (i - 1) / 4), ra * Cos(ang), ra * Sin(ang)
  Next
  Line ra * Cos(a1), ra * Sin(a1), rf * Cos(a1), rf * Sin(a1)
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber

  swApp.CloseAllDocuments True
  NewPart "G"

  ' 1. hub annulus: 2 CCW circles r=0.008 (OD) + r=0.0051 (D-hole), d24
  PlaneSel "G-hub"
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.0051
  CountSegs "G-hub"
  Extr "G-hub", False, 0.024

  ' 2. filler rect rotated thf=94.5deg, d24
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

  ' 3. ring annulus: r=0.022 outer + r=0.008 inner, d18
  PlaneSel "G-ring"
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.022
  md.SketchManager.CreateCircleByRadius 0, 0, 0, 0.008
  CountSegs "G-ring"
  Extr "G-ring", False, 0.018

  ' 4. 5 teeth d18
  Dim k
  For k = 0 To 4
    PlaneSel "G-tooth" & k
    ToothLoop 20, k
    CountSegs "G-tooth" & k
    Extr "G-tooth" & k, False, 0.018
  Next

  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag55_G.SLDPRT", 0, 2)
  L "save", "res=" & res
  Dim res2
  res2 = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag55_G.STL", 0, 2)
  L "stl", "res=" & res2
  swApp.CloseDoc "sw_diag55_G.SLDPRT"
  L "done", "diag55"
End Sub

Call Main
