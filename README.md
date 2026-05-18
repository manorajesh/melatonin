# melatonin

A Windows system tray app that keeps your display awake

## installation

```
git clone https://github.com/manorajesh/melatonin
```

No build step, no dependencies. Requires only PowerShell and Windows Forms, both built into Windows 11.

## usage

Double-click `melatonin.vbs`. No console window appears — it runs entirely as a tray icon.

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

The launcher (`melatonin.vbs`) runs via `wscript.exe`, which has no console, so PowerShell starts fully hidden before any window can flash.

## shortcut

To pin it to the Start menu or taskbar, create a shortcut to `melatonin.vbs` and set a custom icon.

No installation required. Runs entirely on built-in Windows components.
