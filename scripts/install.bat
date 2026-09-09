@echo off
REM ============================================================
REM  DSH Hermes RedTeam — Install Script
REM  Applies the anti-refusal wire-level prefill patch
REM  and installs the Hermes RedTeam agent preset.
REM ============================================================
setlocal enabledelayedexpansion

echo.
echo   DSH Hermes RedTeam — Installer
echo   ------------------------------
echo.

REM --- Detect DSH runtime path ---
set "DSH_BASE=%APPDATA%\DSH Desktop\runtime\dsh"
if not exist "%DSH_BASE%\node_modules\@deepseek-ai" (
    echo [ERROR] DSH runtime not found at: %DSH_BASE%
    echo         Make sure DeepSeek Harness Desktop is installed.
    pause
    exit /b 1
)

REM --- Step 1: Apply wire-level patches ---
echo [1/3] Applying wire-level prefill patches...
set "PATCH_SRC=%~dp0..\patches"
set "DSH_DEEPSEEK=%DSH_BASE%\node_modules\@deepseek-ai\dsh-llm-deepseek\lib\index.js"
set "DSH_PI_AI=%DSH_BASE%\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib\index.js"

if not exist "%PATCH_SRC%\dsh-llm-deepseek-index.js" (
    echo [ERROR] Patch file missing: dsh-llm-deepseek-index.js
    pause
    exit /b 1
)

copy /Y "%PATCH_SRC%\dsh-llm-deepseek-index.js" "%DSH_DEEPSEEK%" >nul
copy /Y "%PATCH_SRC%\dsh-llm-pi-ai-index.js" "%DSH_PI_AI%" >nul
echo          Patches applied.

REM --- Step 2: Install Hermes preset ---
echo [2/3] Installing Hermes RedTeam agent preset...
set "PRESET_SRC=%~dp0..\preset"
set "PRESET_DST=%APPDATA%\DSH Desktop\.agent-presets\redteam"

if not exist "%PRESET_DST%" mkdir "%PRESET_DST%"
copy /Y "%PRESET_SRC%\agent.cordis.yml" "%PRESET_DST%\agent.cordis.yml" >nul
if exist "%PRESET_SRC%\preset.yml" (
    copy /Y "%PRESET_SRC%\preset.yml" "%PRESET_DST%\preset.yml" >nul
)
echo          Preset installed.

REM --- Step 3: Done ---
echo [3/3] Done.
echo.
echo   +--------------------------------------------------+
echo   ^|  RESTART DeepSeek Harness Desktop to apply.       ^|
echo   ^|  Select "redteam" preset in new sessions.         ^|
echo   +--------------------------------------------------+
echo.
pause