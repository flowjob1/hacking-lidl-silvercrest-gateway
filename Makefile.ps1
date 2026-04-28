# Makefile.ps1 - Quick reference for common flash/backup commands on Windows
#
# Usage: .\Makefile.ps1 -Command <command>
#
# Run this script to see available commands, or use:
#   .\Makefile.ps1 -Command help
#   .\Makefile.ps1 -Command backup
#   .\Makefile.ps1 -Command flash-efr32
#   etc.

param(
    [string]$Command = "help",
    [string[]]$Arguments
)

function Show-Help {
    Write-Host ""
    Write-Host "=================================================="
    Write-Host "Gateway Flashing Toolkit - Windows Quick Reference"
    Write-Host "=================================================="
    Write-Host ""
    Write-Host "Available commands:"
    Write-Host ""
    Write-Host "  .\Makefile.ps1 -Command help              Show this help"
    Write-Host "  .\Makefile.ps1 -Command setup             Setup instructions"
    Write-Host ""
    Write-Host "  .\Makefile.ps1 -Command backup [IP]       Backup gateway"
    Write-Host "  .\Makefile.ps1 -Command flash-efr32 [...] Flash EFR32 radio"
    Write-Host "  .\Makefile.ps1 -Command flash-install [IP] Install main firmware"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host ""
    Write-Host "  .\Makefile.ps1 -Command backup"
    Write-Host "  .\Makefile.ps1 -Command flash-efr32 -y ncp"
    Write-Host "  .\Makefile.ps1 -Command flash-install 192.168.1.88"
    Write-Host ""
    Write-Host "For more options, see WINDOWS_PORTING.md"
    Write-Host ""
}

function Show-Setup {
    Write-Host ""
    Write-Host "=================================================="
    Write-Host "Windows Setup Instructions"
    Write-Host "=================================================="
    Write-Host ""
    Write-Host "This toolkit requires one of:"
    Write-Host ""
    Write-Host "1. WSL (Windows Subsystem for Linux) - RECOMMENDED"
    Write-Host "   https://learn.microsoft.com/en-us/windows/wsl/install"
    Write-Host ""
    Write-Host "2. Git Bash"
    Write-Host "   https://git-scm.com/download/win"
    Write-Host ""
    Write-Host "3. MSYS2"
    Write-Host "   https://www.msys2.org/"
    Write-Host ""
    Write-Host "Installation steps:"
    Write-Host ""
    Write-Host "  a) Open PowerShell as Administrator"
    Write-Host "  b) Run: wsl --install"
    Write-Host "  c) Restart computer"
    Write-Host "  d) Then use: wsl ./flash_efr32.sh -y ncp"
    Write-Host ""
    Write-Host "For detailed information:"
    Write-Host "  - Read: WINDOWS_PORTING.md"
    Write-Host "  - Or run: .\Makefile.ps1 -Command help"
    Write-Host ""
}

function Invoke-Backup {
    param([string[]]$Args)
    Write-Host ""
    Write-Host "Backing up gateway..."
    Write-Host ""

    $gwIP = if ($Args.Count -gt 0) { $Args[0] } else { "192.168.1.88" }
    Write-Host "Using gateway IP: $gwIP"
    Write-Host ""

    & wsl ./backup_gateway.sh --linux-ip $gwIP @($Args | Select-Object -Skip 1)

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Warning "Error during backup. Ensure:"
        Write-Host "  - Gateway is reachable at $gwIP"
        Write-Host "  - SSH client is available"
        Write-Host "  - WSL is installed"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Backup completed successfully."
        Write-Host ""
    }
}

function Invoke-FlashEFR32 {
    param([string[]]$Args)
    Write-Host ""
    Write-Host "Flashing EFR32 Zigbee radio..."
    Write-Host ""
    Write-Host "Default: 192.168.1.88 with NCP firmware at 115200 baud"
    Write-Host ""

    & wsl ./flash_efr32.sh @Args

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Warning "Error during flash. Ensure:"
        Write-Host "  - Gateway is reachable"
        Write-Host "  - SSH client is available"
        Write-Host "  - universal-silabs-flasher is installed"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Flash completed successfully."
        Write-Host ""
    }
}

function Invoke-FlashInstall {
    param([string[]]$Args)
    Write-Host ""
    Write-Host "Installing main firmware (RTL8196E)..."
    Write-Host ""

    if ($Args.Count -eq 0) {
        Write-Host "No LINUX_IP provided. Using bootloader mode."
        Write-Host "Make sure gateway is in bootloader mode first!"
    }
    else {
        Write-Host "Using gateway IP: $($Args[0])"
    }
    Write-Host ""

    & wsl ./flash_install_rtl8196e.sh @Args

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Warning "Error during installation. Ensure:"
        Write-Host "  - Gateway is reachable"
        Write-Host "  - SSH client is available"
        Write-Host "  - TFTP is available"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Installation completed successfully."
        Write-Host ""
    }
}

# Main dispatcher
switch ($Command) {
    "help" { Show-Help }
    "setup" { Show-Setup }
    "backup" { Invoke-Backup @Arguments }
    "flash-efr32" { Invoke-FlashEFR32 @Arguments }
    "flash-install" { Invoke-FlashInstall @Arguments }
    default {
        Write-Host "Unknown command: $Command"
        Write-Host "Run '.\Makefile.ps1 -Command help' for available commands."
        exit 1
    }
}

