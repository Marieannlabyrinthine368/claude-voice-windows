#Requires -Version 5.1
<#
.SYNOPSIS
    Enables /voice in Claude Code on Windows by installing SoX and patching cli.js.

.DESCRIPTION
    Claude Code's /voice command doesn't work on Windows because:
    1. The native audio-capture.node binary isn't bundled for Windows
    2. The SoX fallback (used on macOS/Linux) is explicitly blocked on Windows

    This script installs SoX for Windows audio capture and patches cli.js to
    enable the SoX fallback path using the waveaudio driver.

.NOTES
    Run from an elevated PowerShell prompt (Admin) if winget requires it.
    After running, restart your terminal and Claude Code session.
#>

param(
    [switch]$SkipSoX,
    [switch]$Uninstall,
    [switch]$Verify
)

$ErrorActionPreference = "Stop"
$PATCH_MARKER = "PATCHED: allow SoX fallback on Windows"

function Find-CliJs {
    $paths = @(
        "$env:APPDATA\npm\node_modules\@anthropic-ai\claude-code\cli.js"
        "$env:LOCALAPPDATA\npm\node_modules\@anthropic-ai\claude-code\cli.js"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    # Try npm root -g
    try {
        $npmRoot = (npm root -g 2>$null).Trim()
        $p = Join-Path $npmRoot "@anthropic-ai\claude-code\cli.js"
        if (Test-Path $p) { return $p }
    } catch {}
    return $null
}

function Find-Sox {
    try {
        $result = Get-Command sox.exe -ErrorAction SilentlyContinue
        if ($result) { return $result.Source }
    } catch {}
    # Check winget install location
    $wingetPkg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\ChrisBagwell.SoX*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wingetPkg) {
        $sox = Get-ChildItem $wingetPkg.FullName -Recurse -Filter "sox.exe" | Select-Object -First 1
        if ($sox) { return $sox.FullName }
    }
    return $null
}

function Test-Patched {
    param([string]$CliPath)
    return (Select-String -Path $CliPath -Pattern $PATCH_MARKER -Quiet)
}

function Install-SoX {
    Write-Host "`n[1/3] Checking SoX installation..." -ForegroundColor Cyan
    $sox = Find-Sox
    if ($sox) {
        Write-Host "  SoX already installed: $sox" -ForegroundColor Green
        return $true
    }

    Write-Host "  Installing SoX via winget..." -ForegroundColor Yellow
    try {
        winget install ChrisBagwell.SoX --accept-package-agreements --accept-source-agreements
        Write-Host "  SoX installed successfully." -ForegroundColor Green
        Write-Host "  NOTE: Restart your terminal for PATH to update." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "  ERROR: Failed to install SoX via winget." -ForegroundColor Red
        Write-Host "  Install manually from https://sourceforge.net/projects/sox/" -ForegroundColor Red
        Write-Host "  Then add the SoX directory to your PATH." -ForegroundColor Red
        return $false
    }
}

function Install-Patch {
    param([string]$CliPath)

    Write-Host "`n[2/3] Patching cli.js..." -ForegroundColor Cyan
    Write-Host "  File: $CliPath"

    if (Test-Patched $CliPath) {
        Write-Host "  Already patched!" -ForegroundColor Green
        return $true
    }

    # Backup
    $backup = "$CliPath.voice-patch-backup"
    if (-not (Test-Path $backup)) {
        Copy-Item $CliPath $backup
        Write-Host "  Backup saved: $backup"
    }

    $content = [System.IO.File]::ReadAllText($CliPath)
    $patchCount = 0

    # Patch 1: checkRecordingAvailability — remove win32 early-reject
    $old1 = 'if(process.platform==="win32")return{available:!1,reason:"Voice recording requires the native audio module, which could not be loaded."};'
    $new1 = '/* PATCHED: allow SoX fallback on Windows */'
    if ($content.Contains($old1)) {
        $content = $content.Replace($old1, $new1)
        $patchCount++
        Write-Host "  [+] Patch 1: Removed Windows block in checkRecordingAvailability"
    }

    # Patch 2: checkVoiceDependencies — remove win32 early-reject
    $old2 = 'if(process.platform==="win32")return{available:!1,missing:["Voice mode requires the native audio module (not loaded)"],installCommand:null};'
    $new2 = '/* PATCHED: allow SoX fallback on Windows */'
    if ($content.Contains($old2)) {
        $content = $content.Replace($old2, $new2)
        $patchCount++
        Write-Host "  [+] Patch 2: Removed Windows block in checkVoiceDependencies"
    }

    # Patch 3: startRecording — remove win32 early-return
    $old3 = 'if(process.platform==="win32")return k("[voice] Windows native recording unavailable, no fallback"),!1;'
    $new3 = '/* PATCHED: allow SoX rec fallback on Windows */'
    if ($content.Contains($old3)) {
        $content = $content.Replace($old3, $new3)
        $patchCount++
        Write-Host "  [+] Patch 3: Removed Windows block in startRecording"
    }

    # Patch 4: m7z spawn — use sox -t waveaudio default on Windows
    $old4 = 'let _=Y0q("rec",z,{stdio:["pipe","pipe","pipe"]})'
    $new4 = 'let soxCmd="rec",soxArgs=z;if(process.platform==="win32"){soxCmd="sox";soxArgs=["-t","waveaudio","default",...z]}let _=Y0q(soxCmd,soxArgs,{stdio:["pipe","pipe","pipe"]})'
    if ($content.Contains($old4)) {
        $content = $content.Replace($old4, $new4)
        $patchCount++
        Write-Host "  [+] Patch 4: Added waveaudio driver for Windows recording"
    }

    # Patch 5: dl("rec") → dl("sox") on Windows (dependency check)
    $old5 = 'if(!dl("rec"))q.push("sox (rec command)")'
    $new5 = 'if(!(process.platform==="win32"?dl("sox"):dl("rec")))q.push("sox (rec command)")'
    if ($content.Contains($old5)) {
        $content = $content.Replace($old5, $new5)
        $patchCount++
        Write-Host "  [+] Patch 5: Updated dependency check for Windows"
    }

    # Patch 6: dl("rec") in availability check
    $old6 = 'if(!dl("rec")){let q=w0q()'
    $new6 = 'if(!(process.platform==="win32"?dl("sox"):dl("rec"))){let q=w0q()'
    if ($content.Contains($old6)) {
        $content = $content.Replace($old6, $new6)
        $patchCount++
        Write-Host "  [+] Patch 6: Updated availability check for Windows"
    }

    if ($patchCount -eq 0) {
        Write-Host "  WARNING: No patches matched. cli.js may have changed." -ForegroundColor Yellow
        Write-Host "  Claude Code version may be incompatible. Check for updates to this tool." -ForegroundColor Yellow
        return $false
    }

    [System.IO.File]::WriteAllText($CliPath, $content)
    Write-Host "  Applied $patchCount patches." -ForegroundColor Green
    return $true
}

function Test-Voice {
    Write-Host "`n[3/3] Testing audio capture..." -ForegroundColor Cyan

    $sox = Find-Sox
    if (-not $sox) {
        Write-Host "  SoX not found on PATH (restart terminal after install)" -ForegroundColor Yellow
        return $false
    }

    $testScript = @"
const {spawn, spawnSync} = require('child_process');
const dlCheck = spawnSync('where', ['sox'], {stdio:'pipe', timeout:3000});
if (dlCheck.status !== 0) { console.log('FAIL:sox_not_found'); process.exit(1); }
console.log('CHECK:sox_found');
const p = spawn('sox', ['-t','waveaudio','default','-q','--buffer','1024','-t','raw','-r','16000','-e','signed','-b','16','-c','1','-'], {stdio:['pipe','pipe','pipe']});
let got = 0;
p.stdout.on('data', (d) => { got += d.length; });
p.stderr.on('data', (d) => { if(d.toString().includes('FAIL')) console.log('WARN:' + d.toString().trim()); });
p.on('error', (e) => { console.log('FAIL:spawn_error:' + e.message); process.exit(1); });
setTimeout(() => { p.kill(); console.log(got > 0 ? 'PASS:' + got + '_bytes' : 'FAIL:no_audio'); process.exit(got > 0 ? 0 : 1); }, 2000);
"@

    try {
        $result = node -e $testScript 2>&1
        $output = $result -join "`n"

        if ($output -match "PASS:(\d+)_bytes") {
            $bytes = $Matches[1]
            Write-Host "  Audio capture working: $bytes bytes in 2s" -ForegroundColor Green
            return $true
        } elseif ($output -match "FAIL:(.+)") {
            Write-Host "  Audio capture failed: $($Matches[1])" -ForegroundColor Red
            return $false
        } else {
            Write-Host "  Unexpected output: $output" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "  Test failed: $_" -ForegroundColor Red
        return $false
    }
}

function Uninstall-Patch {
    $cliPath = Find-CliJs
    if (-not $cliPath) {
        Write-Host "cli.js not found." -ForegroundColor Red
        return
    }

    $backup = "$cliPath.voice-patch-backup"
    if (Test-Path $backup) {
        Copy-Item $backup $cliPath -Force
        Write-Host "Restored from backup. Patch removed." -ForegroundColor Green
    } else {
        Write-Host "No backup found. Reinstall Claude Code: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    }
}

# ── Main ──

Write-Host ""
Write-Host "claude-voice-windows" -ForegroundColor White
Write-Host "Enable /voice for Claude Code on Windows" -ForegroundColor DarkGray
Write-Host ""

if ($Uninstall) {
    Uninstall-Patch
    exit 0
}

$cliPath = Find-CliJs
if (-not $cliPath) {
    Write-Host "ERROR: Claude Code not found. Install it first:" -ForegroundColor Red
    Write-Host "  npm install -g @anthropic-ai/claude-code" -ForegroundColor White
    exit 1
}

Write-Host "Found Claude Code: $cliPath" -ForegroundColor DarkGray

if ($Verify) {
    if (Test-Patched $cliPath) {
        Write-Host "Status: Patched" -ForegroundColor Green
    } else {
        Write-Host "Status: Not patched" -ForegroundColor Yellow
    }
    Test-Voice | Out-Null
    exit 0
}

$soxOk = if ($SkipSoX) { $true } else { Install-SoX }
$patchOk = Install-Patch $cliPath
$testOk = Test-Voice

Write-Host ""
if ($soxOk -and $patchOk) {
    if ($testOk) {
        Write-Host "Done! Restart Claude Code and run /voice." -ForegroundColor Green
    } else {
        Write-Host "Patches applied. Restart your terminal for PATH to update, then test with:" -ForegroundColor Yellow
        Write-Host "  .\install.ps1 -Verify" -ForegroundColor White
    }
} else {
    Write-Host "Some steps failed. Check the output above." -ForegroundColor Red
    exit 1
}
