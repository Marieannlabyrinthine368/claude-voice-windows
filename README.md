# claude-voice-windows

Enable `/voice` in [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on Windows.

## The Problem

Claude Code's `/voice` command fails on Windows with:

```
Voice recording requires the native audio module, which could not be loaded.
```

This happens because:
1. The native `audio-capture.node` binary isn't shipped for Windows
2. The SoX fallback (which works on macOS/Linux) is explicitly blocked on Windows

**Tracked issues:** [#30915](https://github.com/anthropics/claude-code/issues/30915), [#31065](https://github.com/anthropics/claude-code/issues/31065), [#32249](https://github.com/anthropics/claude-code/issues/32249)

## The Fix

This tool:
1. Installs [SoX](https://sox.sourceforge.net/) (Sound eXchange) for Windows audio capture
2. Patches `cli.js` to enable the SoX fallback on Windows using the `waveaudio` driver

No native compilation needed. No dependencies beyond SoX and Node.js.

## Quick Start

### Option A: One-click (recommended)

Double-click `install.bat` or run in PowerShell:

```powershell
.\install.ps1
```

### Option B: Manual

```powershell
# 1. Install SoX
winget install ChrisBagwell.SoX

# 2. Restart your terminal (PATH update)

# 3. Run the patcher
.\install.ps1 -SkipSoX
```

Then restart Claude Code and run `/voice`.

## What It Patches

Six targeted edits to `cli.js` (backup saved automatically):

| # | Function | What | Why |
|---|----------|------|-----|
| 1 | `checkRecordingAvailability` | Remove win32 early-reject | Let it fall through to SoX check |
| 2 | `checkVoiceDependencies` | Remove win32 early-reject | Same |
| 3 | `startRecording` | Remove win32 early-return | Allow SoX recording path |
| 4 | `m7z` (SoX spawn) | `rec` → `sox -t waveaudio default` | Windows SoX uses waveaudio driver, not `-d` |
| 5 | `b7z` (dep check) | `dl("rec")` → `dl("sox")` on win32 | Windows has `sox.exe`, not `rec` |
| 6 | `u7z` (avail check) | `dl("rec")` → `dl("sox")` on win32 | Same |

## After Claude Code Updates

The patch is applied to `cli.js` which gets overwritten on update. Re-run:

```powershell
.\install.ps1
```

Or if you want to automate it, add a post-install hook or alias.

## Commands

```powershell
.\install.ps1              # Full install (SoX + patch)
.\install.ps1 -SkipSoX     # Patch only (SoX already installed)
.\install.ps1 -Verify       # Check patch status and test audio
.\install.ps1 -Uninstall    # Restore original cli.js from backup
```

## Requirements

- Windows 10/11
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed via npm
- [Node.js](https://nodejs.org/) (comes with Claude Code)
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (pre-installed on Windows 11, available for Windows 10)
- A microphone

## Compatibility

Tested on:
- Windows 11 Home 10.0.26200
- Claude Code v2.1.74
- SoX v14.4.2 (via winget)
- Node.js v24.x

The patch targets specific string patterns in the minified `cli.js`. If Anthropic refactors the voice module, the patch may need updating — open an issue.

## How It Works

On macOS and Linux, when the native audio module fails to load, Claude Code falls back to the `rec` command (part of SoX) to capture audio:

```
rec -q --buffer 1024 -t raw -r 16000 -e signed -b 16 -c 1 -
```

On Windows this fallback is blocked. This patch:
- Removes the three `if(process.platform==="win32") return ...` blocks that prevent fallback
- Replaces the `rec` command with `sox -t waveaudio default` (Windows SoX doesn't include `rec`, and needs the `waveaudio` driver specified explicitly)
- Updates dependency checks to look for `sox.exe` instead of `rec` on Windows

Audio specs: 16kHz, mono, 16-bit signed PCM — matching what Claude Code's voice pipeline expects.

## License

MIT
