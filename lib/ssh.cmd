@echo off
REM lib\ssh.cmd - Windows wrapper for bash SSH helpers
REM
REM This file is primarily for demonstration. The actual SSH helpers
REM are in lib\ssh.sh (bash) and lib\ssh.ps1 (PowerShell).
REM
REM For Windows batch files, directly use 'ssh' command (available via
REM OpenSSH, Git Bash, or WSL).

echo This is a wrapper file for Windows.
echo To use SSH helpers, either:
echo.
echo 1. Source lib\ssh.sh in a bash shell (WSL or Git Bash):
echo    bash ./your_script.sh
echo.
echo 2. Import lib\ssh.ps1 in PowerShell:
echo    . .\lib\ssh.ps1
echo.
echo 3. Use the *.cmd wrapper batch files which automatically detect bash.
echo.

