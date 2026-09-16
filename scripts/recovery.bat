@echo off
REM ============================================================
REM  DSH Hermes RedTeam v4 — Windows Recovery
REM  Restores dsh-agent-loop from backup (.bak) or via npm.
REM  Removes the Hermes preset and AGENTS.md.
REM ============================================================
setlocal enabledelayedexpansion

echo.
echo   DSH Hermes RedTeam v4 — Recovery
echo   ---------------------------------
echo.

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

REM ── [1/4] restore agent-loop ─────────────────────────────────
echo [1/4] Restoring agent-loop...
set "RESTORED=0"
if exist "%BAK%" (
    copy /Y "%BAK%" "%DST%" >nul
    echo          restored from %BAK%
    set "RESTORED=1"
)

REM determine installed version
set "PKG_VER=0.1.6-alpha.1"
if exist "%DSH_BASE%\node_modules\@deepseek-ai\dsh-agent-loop\package.json" (
    for /f "usebackq tokens=2 delims=:, " %%v in ("%DSH_BASE%\node_modules\@deepseek-ai\dsh-agent-loop\package.json") do (
        if "!PKG_VER!"=="0.1.6-alpha.1" set "PKG_VER=%%~v"
    )
)

echo          (re)installing @deepseek-ai/dsh-agent-loop@!PKG_VER! via npm...
pushd "%DSH_BASE%"
call npm install @deepseek-ai/dsh-agent-loop@!PKG_VER! --force --no-audit --no-fund --silent
if errorlevel 1 (
    echo [WARN]  npm install failed; please run manually:
    echo             cd /d "%DSH_BASE%"
    echo             npm install @deepseek-ai/dsh-agent-loop@!PKG_VER! --force
)
popd

REM ── [2/4] clean up .bak ──────────────────────────────────────
if exist "%BAK%" if "!RESTORED!"=="1" (
    del /Q "%BAK%"
    echo          removed stale backup %BAK%
)

REM ── [3/4] remove preset ──────────────────────────────────────
echo [2/4] Removing Hermes RedTeam preset...
set "PRESET_DST=%USERPROFILE%\.dsh-desktop\.agent-presets\redteam"
if exist "%PRESET_DST%" (
    rmdir /S /Q "%PRESET_DST%"
    echo          removed %PRESET_DST%
) else (
    echo          ^(already absent^)
)

REM ── [4/4] remove AGENTS.md ───────────────────────────────────
echo [3/4] Removing workspace AGENTS.md overlay...
set "AGENTS=%USERPROFILE%\.dsh-desktop\AGENTS.md"
if exist "%AGENTS%" (
    del /Q "%AGENTS%"
    echo          removed %AGENTS%
) else (
    echo          ^(already absent^)
)

echo [4/4] Checking settings.yaml for redteam persona override...
set "SETTINGS=%USERPROFILE%\.dsh-desktop\settings.yaml"
if exist "%SETTINGS%" (
    findstr /C:"preset: redteam" "%SETTINGS%" >nul 2>&1
    if not errorlevel 1 (
        echo          [INFO] settings.yaml still references preset=redteam.
        echo                 Open DSH Desktop and switch back to 'standard' preset,
        echo                 or edit settings.yaml and set agentLoop.agents[*].preset: standard.
    )
)

echo.
echo   Recovery complete. RESTART DSH Desktop.
echo.
pause
