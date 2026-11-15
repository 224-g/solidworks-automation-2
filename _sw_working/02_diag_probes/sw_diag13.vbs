' sw_diag13.vbs - prove gear pipeline: stacked-cylinder body + tooth gap cut (spline/arc)
' pure ASCII, logs to sw_diag13.log (UTF-16)
Option Explicit
Dim fso, lf, swApp, md, sk, fm
Set fso = CreateObject("Scripting.FileSystemObject")
Set lf = fso.CreateTextFile("C:\Users\zgzgd\Documents\DSH\sw_diag13.log", True, True)
Sub L(s)
  lf.WriteLine Time & " " & s & " [err=" & Err.Number & " " & Err.Description & "]"
  Err.Clear
End Sub

On Error Resume Next
Set swApp = GetObject("", "SldWorks.Application")
If swApp Is Nothing Then Set swApp = CreateObject("SldWorks.Application")
If swApp Is Nothing Then
  lf.WriteLine "NO SW"
  lf.Close
  WScript.Quit
End If
L "SW attached"
swApp.CloseAllDocuments True
L "closed all docs"
Set md = swApp.NewDocument("C:\ProgramData\SolidWorks\SOLIDWORKS 2024\templates\gb_part.prtdot", 0, 0, 0)
WScript.Sleep 500
L "NewDoc"
Set sk = md.SketchManager
Set fm = md.FeatureManager

' find front plane feature
Dim f, fFront
Set f = md.FirstFeature
Do While Not f Is Nothing
  If f.GetTypeName2 = "RefPlane" Then
    If fFront Is Nothing Then Set fFront = f
  End If
  Set f = f.GetNextFeature
Loop
L "front plane name=" & fFront.Name

Sub StartSketch()
  On Error Resume Next
  md.ClearSelection2 True
  fFront.Select2 False, 1
  sk.InsertSketch False
  L "StartSketch"
End Sub
Sub EndSketch()
  On Error Resume Next
  sk.InsertSketch True
  L "EndSketch"
End Sub
Sub SelSketch()
  On Error Resume Next
  Dim ff, skf
  Set skf = Nothing
  Set ff = md.FirstFeature
  Do While Not ff Is Nothing
    If ff.GetTypeName2 = "ProfileFeature" Then Set skf = ff
    Set ff = ff.GetNextFeature
  Loop
  If skf Is Nothing Then
    L "SelSketch NOSKETCH"
  Else
    skf.Select2 False, 1
    L "SelSketch name=" & skf.Name
  End If
End Sub

' ---- body: 3 stacked cylinders (z1=40 gear: m=2 z=40 d=80) ----
StartSketch
sk.AddToDB = True
sk.CreateCircleByRadius 0, 0, 0, 0.008
sk.AddToDB = False
L "body hub1 circle"
EndSketch
SelSketch
fm.FeatureExtrusion2 True, False, False, 0, 0, 0.006, 0, False,False,False,False, 0,0, False,False,False,False, True,True,True, 0, 0, False
L "hub1 extrude"

StartSketch
sk.AddToDB = True
sk.CreateCircleByRadius 0, 0, 0, 0.042
sk.AddToDB = False
L "ring circle"
EndSketch
SelSketch
fm.FeatureExtrusion2 True, False, False, 0, 0, 0.012, 0, False,False,False,False, 0,0, False,False,False,False, True,True,True, 0, 0.006, False
L "ring extrude off6"

StartSketch
sk.AddToDB = True
sk.CreateCircleByRadius 0, 0, 0, 0.008
sk.AddToDB = False
L "hub2 circle"
EndSketch
SelSketch
fm.FeatureExtrusion2 True, False, False, 0, 0, 0.006, 0, False,False,False,False, 0,0, False,False,False,False, True,True,True, 0, 0.018, False
L "hub2 extrude off18"

' ---- one tooth gap, k=0, z1=40 ----
' rb=37.5877 ra=42 rf=37.5 invp=0.0149044 ua=0.49830 inva=0.035494
' htp=pi/(2z)=0.0392699  psRb=htp+invp=0.0541743  psRa=psRb-inva=0.0186803
' psLb=3pi/(2z)-invp=0.1178097-0.0149044=0.1029053  psLa=psLb+inva=0.1383993
Const PI = 3.14159265358979
Dim psRb, psRa, psLb, psLa, rb, ra, rf
rb = 0.0375877 : ra = 0.042 : rf = 0.0375
psRb = 0.0541743 : psRa = 0.0186803 : psLb = 0.1029053 : psLa = 0.1383993

StartSketch
sk.AddToDB = True
' A radial line rf->rb at psRb
sk.CreateLine rf*Cos(psRb), rf*Sin(psRb), 0, rb*Cos(psRb), rb*Sin(psRb), 0
L "gap A radial"
' B involute spline u=0..ua
Dim pts(26), u, i, ang, rr
For i = 0 To 8
  u = (0.49830 * i) / 8
  rr = rb * Sqr(1 + u*u)
  ang = psRb - (u - Atn(u))
  pts(i*3) = rr * Cos(ang)
  pts(i*3+1) = rr * Sin(ang)
  pts(i*3+2) = 0
Next
sk.CreateSpline2 pts, True
L "gap B spline"
' C tip arc psRa -> psLa CCW
sk.CreateArc 0, 0, 0, ra*Cos(psRa), ra*Sin(psRa), 0, ra*Cos(psLa), ra*Sin(psLa), 0, 1
L "gap C tiparc"
' D left flank spline u=ua..0
For i = 0 To 8
  u = 0.49830 * (1 - i / 8)
  rr = rb * Sqr(1 + u*u)
  ang = psLb + (u - Atn(u))
  pts(i*3) = rr * Cos(ang)
  pts(i*3+1) = rr * Sin(ang)
  pts(i*3+2) = 0
Next
sk.CreateSpline2 pts, True
L "gap D spline"
' E radial line rb->rf at psLb
sk.CreateLine rb*Cos(psLb), rb*Sin(psLb), 0, rf*Cos(psLb), rf*Sin(psLb), 0
L "gap E radial"
' F root arc psLb -> psRb CW
sk.CreateArc 0, 0, 0, rf*Cos(psLb), rf*Sin(psLb), 0, rf*Cos(psRb), rf*Sin(psRb), 0, -1
L "gap F rootarc"
sk.AddToDB = False
EndSketch
SelSketch
' FeatureCut4 27 args
fm.FeatureCut4 True, False, False, 1, 0, 0.001, 0, False,False,False,False, 0,0, False,False,False,False, False,True,True, False,False,False, 0, 0, False, False
L "gap cut 27args"

' check body state
Dim bodies
Set bodies = md.GetBodies2(0, True)
L "bodies count=" & bodies.Count
If bodies.Count > 0 Then
  L "body0 type=" & bodies.Item(0).GetTypeName2
End If

md.ShowNamedView2 "*Isometric", 7
WScript.Sleep 800
md.SaveBMP "C:\Users\zgzgd\Documents\DSH\sw_shots\diag13_gear.bmp", 0, 0
L "saved bmp"
md.SaveAs3 "C:\Users\zgzgd\Documents\DSH\sw_diag13_gear.SLDPRT", 0, 2
L "saved part res"
L "DONE"
lf.Close
WScript.Quit
