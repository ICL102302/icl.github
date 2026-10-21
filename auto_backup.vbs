' Runs auto_backup.ps1 from Task Scheduler without showing a window.
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""G:\icl.github\auto_backup.ps1""", 0, False
