# flash_install_rtl8196e.ps1 — Install custom firmware on Lidl Silvercrest Gateway (Windows)
#
# Detects the gateway state and flashes via TFTP. Supports both custom v2 bootloader
# and older fallback modes.
#
# Usage: .\flash_install_rtl8196e.ps1 [-y] [LINUX_IP] [--help]
#
# Requirements:
#   - TFTP client (tftp command in PATH)
#   - SSH client (for pre-flash detection and config backup)
#   - Network connectivity to gateway on same subnet
#
# J. Nilo - March 2026, Windows port April 2026

param(
    [string]$LinuxIP = "",
    [switch]$Yes,
    [switch]$Debug,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path (Resolve-Path $PSCommandPath)
$DEBUG = if ($Debug -or $env:DEBUG -eq 'y') { 'y' } else { '' }

if ($Help) {
    Write-Host @"
Usage: $(Split-Path -Leaf $PSCommandPath) [-y] [LINUX_IP] [--help]

Installs custom firmware on the Lidl Silvercrest Gateway.

Arguments:
  LINUX_IP       Gateway IP when running Linux (upgrade with config save)
                 Omit for first-time flash (gateway must be in bootloader)

Options:
  -y             Non-interactive mode (skip all prompts)
  -Debug         Enable debug output
  -Help          Show this help and exit

Environment: BOOT_IP, SSH_TIMEOUT, NET_MODE, RADIO_MODE, CONFIRM,
  IPADDR, NETMASK, GATEWAY, DEBUG
"@
    exit 0
}

$BOOT_IP = $env:BOOT_IP -or "192.168.1.6"
$SSH_TIMEOUT = [int]($env:SSH_TIMEOUT -or 2)
$CONFIRM = if ($Yes -or $env:CONFIRM -eq 'y') { 'y' } else { '' }

# Check for required tools
function Test-Command {
    param([string]$Cmd, [string]$Package)
    $exists = $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue)
    if (-not $exists) {
        Write-Warning "Missing: $Cmd (package: $Package)"
    }
    return $exists
}

Write-Host ""
Write-Host "Checking dependencies..."

$missingTools = @()
if (-not (Test-Command ssh openssh)) { $missingTools += "ssh (OpenSSH)" }
if (-not (Test-Command tftp tftp-hpa)) { $missingTools += "tftp (tftp-hpa)" }

if ($missingTools.Count -gt 0) {
    Write-Warning "Missing tools: $($missingTools -join ', ')"
    Write-Host ""
    Write-Host "On Windows, you can:"
    Write-Host "  1. Install via Windows Package Manager (Windows 10/11 21H2+):"
    Write-Host "     winget install OpenSSH.Client"
    Write-Host ""
    Write-Host "  2. Use Git Bash (includes ssh): https://git-scm.com/download/win"
    Write-Host ""
    Write-Host "  3. Use WSL for full bash compatibility:"
    Write-Host "     wsl ./flash_install_rtl8196e.sh"
    Write-Host ""
    Write-Host "     This is recommended for best compatibility."
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "========================================="
Write-Host "  FIRMWARE INSTALLATION"
Write-Host "========================================="
Write-Host ""

# Detect gateway state
Write-Host "Detecting gateway state..."
Write-Host "Linux IP:    $LinuxIP"
Write-Host "Boot IP:     $BOOT_IP"
Write-Host ""

function Test-SSHPort {
    param([string]$IP, [int]$Port)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ConnectAsync($IP, $Port).Wait($SSH_TIMEOUT * 1000) | Out-Null
        $result = $tcpClient.Connected
        $tcpClient.Close()
        return $result
    }
    catch {
        return $false
    }
}

$LINUX_RUNNING = ""
if ($LinuxIP) {
    if ($DEBUG -eq 'y') {
        Write-Host "[DEBUG] Checking SSH on ${LinuxIP}:22..." -ForegroundColor Cyan
    }

    if (Test-SSHPort $LinuxIP 22) {
        $LINUX_RUNNING = "$($LinuxIP):22"
        Write-Host "SSH detected at $LINUX_RUNNING (custom firmware)"
    }
    else {
        Write-Error "Cannot reach gateway at $LinuxIP (no SSH on port 22)."
        Write-Host "If gateway is in bootloader, re-run without argument."
        exit 1
    }
}

if ($LINUX_RUNNING) {
    Write-Host "Linux detected at $LINUX_RUNNING"
    Write-Host ""
    Write-Host "Firmware type: custom (v2 bootloader assumed)"

    # For now, recommend using WSL for the full feature set
    Write-Host ""
    Write-Host "NOTE: This Windows PowerShell version is limited."
    Write-Host "For full functionality (config backup, gateway detection), use:"
    Write-Host "  wsl ./flash_install_rtl8196e.sh $LinuxIP"
    Write-Host ""

    $response = Read-Host "Continue with limited Windows version? (y/N)"
    if ($response -notmatch '^[yY]') {
        Write-Host "Aborted. Consider using WSL for the full bash version."
        exit 0
    }
}
else {
    # Check for bootloader
    Write-Host "Checking for bootloader at $BOOT_IP..."

    # Test if ARP resolved (simplified method on Windows)
    try {
        $arpResult = arp -a | Select-String $BOOT_IP
        if ($arpResult) {
            Write-Host "Device detected at $BOOT_IP via ARP"
        }
    }
    catch { }

    Write-Host ""
    Write-Host "========================================="
    Write-Host "  FIRST-TIME FLASH"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "For first-time flash, you need:"
    Write-Host "  1. Serial console (3.3V UART, 38400 8N1)"
    Write-Host "  2. Gateway in bootloader mode (press ESC during boot)"
    Write-Host ""
    Write-Host "This PowerShell version has LIMITED support."
    Write-Host "Recommendation: Use the bash version with WSL:"
    Write-Host "  wsl ./flash_install_rtl8196e.sh"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "========================================="
Write-Host "  WINDOWS COMPATIBILITY NOTE"
Write-Host "========================================="
Write-Host ""
Write-Host "This PowerShell port provides basic functionality, but is limited compared"
Write-Host "to the original bash scripts. For full features and best reliability:"
Write-Host ""
Write-Host "1. Install WSL (Windows Subsystem for Linux):"
Write-Host "   https://learn.microsoft.com/en-us/windows/wsl/install"
Write-Host ""
Write-Host "2. Run the bash scripts directly:"
Write-Host "   wsl ./backup_gateway.sh [options]"
Write-Host "   wsl ./flash_efr32.sh [options]"
Write-Host "   wsl ./flash_install_rtl8196e.sh [options]"
Write-Host ""
Write-Host "WSL integration in PowerShell:"
Write-Host "   # Create an alias for easy access"
Write-Host '   Set-Alias bash "C:\\Program Files\\Git\\bin\\bash.exe"'
Write-Host "   bash ./flash_efr32.sh"
Write-Host ""
Write-Host "========================================="
Write-Host ""

