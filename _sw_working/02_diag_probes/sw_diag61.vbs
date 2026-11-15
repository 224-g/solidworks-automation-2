' sw_diag61.vbs - isolate z40 tooth failure: one tooth + seg counts
Option Explicit
On Error Resume Next
Dim swApp, md, ft
Dim LOG, lf
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag61.log", 8, True)
Set lf = LOG
Sub L(tag, msg)
  lf.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub
Const PI = 3.14159265358979
Dim gPartTpl
gPartTpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot"

Sub PlaneSel(tag)
  md.ClearSelection2 True
  Dim b : b = md.Extension.SelectByID2("", "PLANE", 0, 0, 0, False, 0, Nothing, 0)
  md.SketchManager.InsertSketch False
  L tag, "plane sel=" & b
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
    L tag, "selsk NONE"
    Exit Sub
  End If
  Dim b : b = md.Extension.SelectByID2(lastN, "SKETCH", 0, 0, 0, False, 0, Nothing, 0)
  L tag, "selsk " & lastN & " res=" & b
End Sub
Sub Extr(tag, flip, d)
  md.SketchManager.InsertSketch True
  SelSk tag
  Set ft = md.FeatureManager.FeatureExtrusion2(True, flip, False, 0, 0, d, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
  If ft Is Nothing Then
    L tag, "EXTR FAILED"
  Else
    L tag, "OK " & ft.Name
  End If
End Sub
Sub Line(x1, y1, x2, y2)
  md.SketchManager.CreateLine x1, y1, 0, x2, y2, 0
End Sub
Sub Circ(x, y, r)
  md.SketchManager.CreateCircleByRadius x, y, 0, r
End Sub
Sub Arc2(x1, y1, x2, y2, dirn)
  md.SketchManager.CreateArc 0, 0, 0, x1, y1, 0, x2, y2, 0, dirn
End Sub
Sub CountSegs(tag)
  WScript.Sleep 300
  Dim segs, ub
  Set segs = md.SketchManager.ActiveSketch.GetSketchSegments
  ub = UBound(segs)
  L tag, "segs=" & (ub + 1)
End Sub

Sub ToothLoop(z, j)
  Dim m : m = 0.002
  Dim al : al = 20 * PI / 180
  Dim rp : rp = m * z / 2
  Dim rb : rb = rp * Cos(al)
  Dim ra : ra = rp + m
  Dim rf : rf = rp - 1.25 * m
  Dim invp : invp = Tan(al) - al
  Dim ua : ua = Sqr((ra / rb) * (ra / rb) - 1)
  Dim inva : inva = ua - Atn(ua)
  Dim htp : htp = PI / (2 * z)
  Dim psLbPrev : psLbPrev = (j - 1) * 2 * PI / z + 3 * PI / (2 * z) - invp
  Dim psRbJ : psRbJ = j * 2 * PI / z + htp + invp
  Dim psRaJ : psRaJ = psRbJ - inva
  Dim psLaPrev : psLaPrev = psLbPrev + inva
  Dim i, u, r1, r2, a1, a2
  L "tooth", "z=" & z & " rb=" & FormatNumber(rb,5) & " ra=" & ra & " rf=" & rf & " psLb=" & FormatNumber(psLbPrev,5) & " psRb=" & FormatNumber(psRbJ,5)
  Arc2 rf * Cos(psLbPrev), rf * Sin(psLbPrev), rf * Cos(psRbJ), rf * Sin(psRbJ), 1
  Line rf * Cos(psRbJ), rf * Sin(psRbJ), rb * Cos(psRbJ), rb * Sin(psRbJ)
  r1 = rb : a1 = psRbJ
  For i = 1 To 8
    u = ua * i / 8
    r2 = rb * Sqr(1 + u * u)
    a2 = psRbJ - (u - Atn(u))
    Line r1 * Cos(a1), r1 * Sin(a1), r2 * Cos(a2), r2 * Sin(a2)
    r1 = r2 : a1 = a2
  Next
  Dim ti, ta
  For i = 1 To 4
    ta = psRaJ + (psLaPrev - psRaJ) * i / 4
    Line ra * Cos(psRaJ + (psLaPrev - psRaJ) * (i - 1) / 4), ra * Sin(psRaJ + (psLaPrev - psRaJ) * (i - 1) / 4), ra * Cos(ta), ra * Sin(ta)
  Next
  r1 = ra : a1 = psLaPrev
  For i = 7 To 0 Step -1
    u = ua * i / 8
    r2 = rb * Sqr(1 + u * u)
    a2 = psLbPrev + (u - Atn(u))
    Line r1 * Cos(a1), r1 * Sin(a1), r2 * Cos(a2), r2 * Sin(a2)
    r1 = r2 : a1 = a2
  Next
  Line rb * Cos(psLbPrev), rb * Sin(psLbPrev), rf * Cos(psLbPrev), rf * Sin(psLbPrev)
End Sub

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "attached rev=" & swApp.RevisionNumber
  swApp.CloseAllDocuments True
  Set md = swApp.NewDocument(gPartTpl, 0, 0, 0)
  WScript.Sleep 500
  L "main", "newdoc"

  PlaneSel "ring"
  Circ 0, 0, 0.042
  Circ 0, 0, 0.008
  CountSegs "ring"
  Extr "ring", False, 0.018

  PlaneSel "tooth0"
  ToothLoop 40, 0
  CountSegs "tooth0"
  Extr "tooth0", False, 0.018

  Dim res
  res = md.SaveAs3("C:\Users\zgzgd\Documents\DSH\sw_diag61.SLDPRT", 0, 2)
  L "save", "res=" & res
  swApp.CloseDoc "sw_diag61.SLDPRT"
  L "done", "diag61"
End Sub

Call Main
