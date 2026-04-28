@echo off
REM flash_install_rtl8196e.cmd - Windows wrapper for flash_install_rtl8196e.sh (WSL compatible)
REM
REM Usage: flash_install_rtl8196e.cmd [-y] [LINUX_IP]
REM
REM Automatically uses WSL if available, with fallback to Git Bash or error message.

setlocal enabledelayedexpansion

REM Check if WSL is available
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    REM WSL found - use native bash script
    wsl ./flash_install_rtl8196e.sh %*
    exit /b !errorlevel!
) else if exist "C:\Program Files\Git\bin\bash.exe" (
    REM Git Bash available as fallback
    "C:\Program Files\Git\bin\bash.exe" ./flash_install_rtl8196e.sh %*
    exit /b !errorlevel!
) else (
    echo.
    echo Error: No bash shell found on this system.
    echo.
    echo To install firmware on the gateway from Windows, install one of:
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
    echo Usage: flash_install_rtl8196e.cmd [-y] [LINUX_IP]
    echo.
    echo For help: flash_install_rtl8196e.cmd --help
    echo.
    exit /b 1
)

