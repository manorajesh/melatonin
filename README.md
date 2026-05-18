# melatonin

A Windows system tray app that keeps your display awake — named after the sleep hormone, not a stimulant.

Every other keep-awake app is named after something that wires you up: Caffeine, Amphetamine, Theine. melatonin is the opposite: it's the thing your body produces to put you to sleep, quietly doing the exact job it was never meant to do.

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
