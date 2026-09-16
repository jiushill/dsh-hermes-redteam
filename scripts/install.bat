@echo off
REM ============================================================
REM  DSH Hermes RedTeam v4 — Windows Installer
REM  Patches dsh-agent-loop and installs the Hermes preset.
REM  Run as Administrator if %APPDATA%\DSH Desktop is read-only.
REM ============================================================
setlocal enabledelayedexpansion

echo.
echo   DSH Hermes RedTeam v4 — Installer
echo   ----------------------------------
echo   Patches: agent-loop only (system prompt suffix)
echo   Adapters: UNTOUCHED (zero bugs)
echo.

set "SRC_DIR=%~dp0..\dsh-hermes-redteam"
if not exist "%SRC_DIR%\patches\dsh-agent-loop-index.js" (
    echo [ERROR] source patch missing: %SRC_DIR%\patches\dsh-agent-loop-index.js
    pause
    exit /b 1
)

REM ── locate runtime ────────────────────────────────────────────
set "DSH_BASE=%APPDATA%\DSH Desktop\runtime\dsh"
if not exist "%DSH_BASE%\node_modules\@deepseek-ai" (
    set "DSH_BASE=%LOCALAPPDATA%\dsh-desktop\resources\harness"
)
if not exist "%DSH_BASE%\node_modules\@deepseek-ai" (
    if defined DSH_HOME set "DSH_BASE=%DSH_HOME%\resources\harness"
)
if not exist "%DSH_BASE%\node_modules\@deepseek-ai" (
    echo [ERROR] DSH runtime not found.
    echo         Set DSH_HOME and retry.
    pause
    exit /b 1
)

set "DST=%DSH_BASE%\node_modules\@deepseek-ai\dsh-agent-loop\lib\index.js"
set "BAK=%DST%.bak"
if not exist "%DST%" (
    echo [ERROR] target file missing: %DST%
    pause
    exit /b 1
)

REM ── [1/3] patch agent-loop ───────────────────────────────────
echo [1/3] Patching agent-loop with system prompt suffix...
copy /Y "%SRC_DIR%\patches\dsh-agent-loop-index.js" "%DST%" >nul
echo          agent-loop patched.

REM ── [2/3] install preset ─────────────────────────────────────
echo [2/3] Installing Hermes RedTeam preset...
set "PRESET_DST=%USERPROFILE%\.dsh-desktop\.agent-presets\redteam"
if not exist "%PRESET_DST%" mkdir "%PRESET_DST%"
copy /Y "%SRC_DIR%\preset\agent.cordis.yml" "%PRESET_DST%\agent.cordis.yml" >nul
copy /Y "%SRC_DIR%\preset\preset.yml"      "%PRESET_DST%\preset.yml" >nul
echo          preset installed.

REM ── [3/3] stage AGENTS.md ───────────────────────────────────
echo [3/3] Staging workspace AGENTS.md...
copy /Y "%SRC_DIR%\AGENTS.md" "%USERPROFILE%\.dsh-desktop\AGENTS.md" >nul

echo.
echo   Done. RESTART DSH Desktop. Select 'redteam' preset.
echo.
echo   How it works:
echo   - A suffix is appended to the END of the rendered system prompt
echo   - Recency effect pushes model past refusal point
echo   - No adapter hacks = no reasoning_content / totalTokens bugs
echo.
echo   To revert, run: scripts\recovery.bat
echo.
pause
