# melatonin

A Windows system tray app that keeps your display awake

## installation

```
git clone https://github.com/manorajesh/melatonin
```

No build step, no dependencies. Requires only PowerShell and Windows Forms, both built into Windows 11.

## usage

```
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File melatonin.ps1
```

A small circle appears in the system tray. Right-click it:

| option | effect |
|---|---|
| **wide awake** | suppresses sleep — display stays on |
| **getting drowsy** | releases control — normal sleep settings resume |
| **goodnight** | exits |

Starts in **wide awake** mode. Green dot = suppressing. Gray dot = released.

## how it works

Uses the Windows `SetThreadExecutionState` API with `ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED` — the same mechanism video players use to prevent sleep during playback. No mouse jiggling, no fake keypresses. Refreshes the state every 30 seconds.

## shortcut

To make it launchable without a terminal, create a shortcut with this target:

```
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\melatonin.ps1"
```

No installation required. Runs entirely on built-in Windows components.
