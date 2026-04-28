@echo off
REM flash_efr32.cmd - Windows wrapper for flash_efr32.sh (WSL compatible)
REM
REM Usage: flash_efr32.cmd [OPTIONS] [FIRMWARE [BAUD]]
REM
REM Automatically uses WSL if available, with fallback to Git Bash or error message.

setlocal enabledelayedexpansion

REM Check if WSL is available
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    REM WSL found - use native bash script
    wsl ./flash_efr32.sh %*
    exit /b !errorlevel!
) else if exist "C:\Program Files\Git\bin\bash.exe" (
    REM Git Bash available as fallback
    "C:\Program Files\Git\bin\bash.exe" ./flash_efr32.sh %*
    exit /b !errorlevel!
) else (
    echo.
    echo Error: No bash shell found on this system.
    echo.
    echo To flash the EFR32 on Windows, install one of:
    echo.
    echo   1. WSL (Windows Subsystem for Linux) - RECOMMENDED:
    echo      https://learn.microsoft.com/en-us/windows/wsl/install
    echo.
    echo   2. Git Bash:
    echo      https://git-scm.com/download/win
    echo.
    echo   3. MSYS2:
    echo      https://www.msys2.org/
    echo.
    echo After installation, try again.
    echo.
    echo Usage: flash_efr32.cmd [OPTIONS] [FIRMWARE [BAUD]]
    echo.
    echo For help: flash_efr32.cmd --help
    echo.
    exit /b 1
)

