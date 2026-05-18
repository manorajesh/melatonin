# melatonin

A Windows system tray app that keeps your display awake without elevated privileges or installing an application.

## installation

```
git clone https://github.com/manorajesh/melatonin
```

No build step, no dependencies. Requires __only__ PowerShell and Windows Forms, both built into Windows 11.

## usage

Create a Windows shortcut with this target:

```
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\path\to\melatonin.ps1"
```

Set **Run: Minimized** in the shortcut properties. Double-clicking it launches melatonin as a tray icon with only a brief taskbar flash on startup.

Right-click the tray icon:

| option | effect |
|---|---|
| **wide awake** | suppresses sleep — display stays on |
| **getting drowsy** | releases control — normal sleep settings resume |
| **dream log** | shows any errors from the current session |
| **goodnight** | exits |

Starts in **wide awake** mode. Green dot = suppressing. Gray dot = released.

## how it works

Uses the Windows `SetThreadExecutionState` API with `ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED` — the same mechanism video players use to prevent sleep during playback. No mouse jiggling, no fake keypresses. Refreshes the state every 30 seconds.

## shortcut

To pin to the Start menu or taskbar, right-click the shortcut → Pin to Start / Pin to taskbar.

No installation required. Runs entirely on built-in Windows components.
