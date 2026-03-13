@echo off
:: One-click installer for claude-voice-windows
:: Right-click > Run as Administrator (if winget needs elevation)
echo.
echo claude-voice-windows - Enable /voice for Claude Code on Windows
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
