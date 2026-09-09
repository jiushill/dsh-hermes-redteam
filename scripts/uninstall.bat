@echo off
REM ============================================================
REM  DSH Hermes RedTeam v4 — Uninstall Script
REM  Restores agent-loop from npm (adapters were never touched).
REM ============================================================
setlocal

echo.
echo   DSH Hermes RedTeam v4 — Uninstaller
echo   ------------------------------------
echo.

set "DSH_BASE=%APPDATA%\DSH Desktop\runtime\dsh"
if not exist "%DSH_BASE%\package.json" (
    echo [ERROR] DSH runtime not found.
    pause
    exit /b 1
)

echo [1/2] Restoring agent-loop from npm...
cd /d "%DSH_BASE%"
call npm install @deepseek-ai/dsh-agent-loop@0.1.1-rc.2 --force
if %ERRORLEVEL% neq 0 (
    echo [WARN] Try manually:
    echo        cd "%DSH_BASE%"
    echo        npm install @deepseek-ai/dsh-agent-loop@0.1.1-rc.2 --force
)

echo [2/2] Done. Preset and AGENTS.md remain — delete manually if desired.
echo.
echo   RESTART DeepSeek Harness Desktop.
pause