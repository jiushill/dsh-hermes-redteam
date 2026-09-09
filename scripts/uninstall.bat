@echo off
REM ============================================================
REM  DSH Hermes RedTeam v3 — Uninstall Script
REM  Restores original pi-ai adapter from npm.
REM  DeepSeek adapter was never modified.
REM ============================================================
setlocal

echo.
echo   DSH Hermes RedTeam v3 — Uninstaller
echo   ------------------------------------
echo.

set "DSH_BASE=%APPDATA%\DSH Desktop\runtime\dsh"
if not exist "%DSH_BASE%\package.json" (
    echo [ERROR] DSH runtime not found.
    pause
    exit /b 1
)

echo [1/2] Restoring original pi-ai adapter from npm...
cd /d "%DSH_BASE%"
call npm install @deepseek-ai/dsh-llm-pi-ai@0.1.1-rc.2 --force
if %ERRORLEVEL% neq 0 (
    echo [WARN] npm install failed. Try manually:
    echo        cd "%DSH_BASE%"
    echo        npm install @deepseek-ai/dsh-llm-pi-ai@0.1.1-rc.2 --force
)

echo [2/2] Done. Preset at %%APPDATA%%\DSH Desktop\.agent-presets\redteam\ remains.
echo        Delete it manually if desired.
echo        AGENTS.md at %%USERPROFILE%%\.dsh\AGENTS.md also remains.
echo.
echo   RESTART DeepSeek Harness Desktop.
pause