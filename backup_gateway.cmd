@echo off
REM backup_gateway.cmd - Windows wrapper for backup_gateway.sh (WSL compatible)
REM
REM Usage: backup_gateway.cmd [--linux-ip IP] [--boot-ip IP] [--output DIR]
REM
REM If WSL is available, uses native bash. Otherwise shows setup instructions.

setlocal enabledelayedexpansion

REM Check if WSL is available
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    REM WSL found - use native bash script
    wsl ./backup_gateway.sh %*
    exit /b !errorlevel!
) else if exist "C:\Program Files\Git\bin\bash.exe" (
    REM Git Bash available as fallback
    "C:\Program Files\Git\bin\bash.exe" ./backup_gateway.sh %*
    exit /b !errorlevel!
) else (
    echo.
    echo Error: No bash shell found on this system.
    echo.
    echo To use backup_gateway.sh on Windows, install one of:
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
    exit /b 1
)

