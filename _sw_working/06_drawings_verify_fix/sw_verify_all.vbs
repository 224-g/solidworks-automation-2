' sw_verify_all.vbs - mass-props verification of all 17 parts
Option Explicit
On Error Resume Next
Dim swApp, md, mp
Dim LOG
Set LOG = CreateObject("Scripting.FileSystemObject").OpenTextFile("C:\Users\zgzgd\Documents\DSH\sw_verify_all.log", 8, True)
Sub L(tag, msg)
  LOG.WriteLine Time & " " & tag & " " & msg & " [err=" & Err.Number & "]"
  Err.Clear
End Sub

Dim gParts(16), gName(16)
gName(0) = "plate"   : gParts(0) = "plate.SLDPRT"
gName(1) = "bracket" : gParts(1) = "bracket.SLDPRT"
gName(2) = "tower"   : gParts(2) = "tower.SLDPRT"
gName(3) = "shaft1"  : gParts(3) = "shaft1.SLDPRT"
gName(4) = "shaft2"  : gParts(4) = "shaft2.SLDPRT"
gName(5) = "gear1"   : gParts(5) = "gear1.SLDPRT"
gName(6) = "gear2"   : gParts(6) = "gear2.SLDPRT"
gName(7) = "crank"   : gParts(7) = "crank.SLDPRT"
gName(8) = "pin"     : gParts(8) = "pin.SLDPRT"
gName(9) = "rod"     : gParts(9) = "rod.SLDPRT"
gName(10) = "slider" : gParts(10) = "slider.SLDPRT"
gName(11) = "rail"   : gParts(11) = "rail.SLDPRT"
gName(12) = "motor"  : gParts(12) = "motor.SLDPRT"
gName(13) = "anvil"  : gParts(13) = "anvil.SLDPRT"
gName(14) = "work"   : gParts(14) = "work.SLDPRT"
gName(15) = "bolt"   : gParts(15) = "bolt.SLDPRT"
gName(16) = "nut"    : gParts(16) = "nut.SLDPRT"

Sub Main()
  On Error Resume Next
  Set swApp = CreateObject("SldWorks.Application")
  L "start", "rev=" & swApp.RevisionNumber
  Dim i
  For i = 0 To 16
    swApp.CloseAllDocuments True
    Set md = swApp.OpenDoc("C:\Users\zgzgd\Documents\DSH\sw_parts8\" & gParts(i), 1)
    If md Is Nothing Then
      L gName(i), "OPEN FAILED"
    Else
      Set mp = md.Extension.CreateMassProperty
      mp.UseSystemUnits = False
      Dim vol : vol = mp.Volume
      L gName(i), "vol=" & FormatNumber(vol, 1)
      swApp.CloseDoc gParts(i)
    End If
    WScript.Sleep 300
  Next
  L "done", "verify complete"
End Sub

Call Main
