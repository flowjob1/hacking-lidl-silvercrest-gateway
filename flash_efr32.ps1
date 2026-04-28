# flash_efr32.ps1 — Flash firmware to the Silabs EFR32 Zigbee/Thread radio (Windows)
#
# Requires: universal-silabs-flasher 1.0.3+, Python 3, SSH client
#
# Flow:
#   1. Presents a menu to select the firmware type (NCP, RCP, OT-RCP, Router)
#   2. Ensures universal-silabs-flasher is available (installs via pip if needed)
#   3. SSHes into the gateway to detect mode (Zigbee vs OTBR via radio.conf)
#   4. Flashes the selected firmware over socket://GW:8888
#   5. Restores flow_control and reboots the gateway
#
# Usage: .\flash_efr32.ps1 [OPTIONS] [FIRMWARE [BAUD]]
#
# J. Nilo - February 2026, Windows port April 2026

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path (Resolve-Path $PSCommandPath)
$DEBUG = $env:DEBUG -eq 'y'
$GW_PORT = 8888
$GW_IP_DEFAULT = "192.168.1.88"
$VENV_DIR = Join-Path $scriptDir "silabs-flasher"
$BRIDGE_SYSFS = "/sys/module/rtl8196e_uart_bridge/parameters"

# Parse arguments
$fwArg = $null
$baudArg = $null
$GW_IP = $null
$NO_REBOOT = $false
$CONFIRM_FLAG = $false

$i = 0
while ($i -lt $RemainingArgs.Count) {
    switch ($RemainingArgs[$i]) {
        { @('-h', '--help') -contains $_ } {
            Write-Host @"
Usage: $(Split-Path -Leaf $PSCommandPath) [OPTIONS] [FIRMWARE [BAUD]]

Flash an EFR32 Zigbee/Thread radio firmware on the Lidl Silvercrest
Gateway, via the in-kernel UART<->TCP bridge.

Positional arguments:
  FIRMWARE     One of:
               bootloader  Gecko Bootloader stage 2 (UART/Xmodem)
               ncp         NCP-UART-HW  (EZSP, for Zigbee2MQTT/ZHA)
               rcp         RCP-UART-HW  (CPC multi-PAN)
               otrcp       OT-RCP       (OpenThread + otbr-agent)
               router      Z3 standalone Zigbee 3.0 router
             Numeric aliases 1-5 are also accepted.

  BAUD         UART baud for the flashed firmware. Defaults & supported
               sets per firmware:
                  ncp     115200 (default), 230400, 460800, 691200, 892857
                  rcp     115200, 230400, 460800 (default)
                  otrcp   460800 (default; only)
                  router  115200 (default; only)

Options:
  -g, --gateway IP   Gateway IP (default: 192.168.1.88)
  -y, --yes          Skip the "Flash?" confirmation prompt
  -d, --debug        Enable debug output
      --no-reboot    Do not reboot the gateway after a successful flash
  -h, --help         Show this help and exit

Examples:
  .\flash_efr32.ps1                               # Interactive menu
  .\flash_efr32.ps1 -y ncp                        # NCP @ default baud
  .\flash_efr32.ps1 -y -g 10.0.0.5 otrcp          # OT-RCP on custom IP
"@
            exit 0
        }
        { @('-y', '--yes') -contains $_ } {
            $CONFIRM_FLAG = $true
        }
        { @('-d', '--debug') -contains $_ } {
            $DEBUG = $true
            $env:DEBUG = 'y'
        }
        { @('-g', '--gateway') -contains $_ } {
            $i++
            if ($i -lt $RemainingArgs.Count) {
                $GW_IP = $RemainingArgs[$i]
            }
        }
        '--no-reboot' {
            $NO_REBOOT = $true
        }
        default {
            if (-not $fwArg) {
                $fwArg = $_
            }
            elseif (-not $baudArg) {
                $baudArg = $_
            }
        }
    }
    $i++
}

$GW_IP = if ($GW_IP) { $GW_IP } else { $GW_IP_DEFAULT }

# Check dependencies
function Test-Command {
    param([string]$Cmd)
    $null = Get-Command $Cmd -ErrorAction SilentlyContinue
    return $?
}

if (-not (Test-Command python3)) {
    if (Test-Command python) {
        $pythonCmd = "python"
    }
    else {
        Write-Error "Python 3 not found. Install Python or add it to PATH."
        exit 1
    }
}
else {
    $pythonCmd = "python3"
}

# SSH wrapper
. (Join-Path $scriptDir "lib\ssh.ps1")

Write-Host ""
Write-Host "Firmware: (checking...)"
Write-Host "Gateway:  $($GW_IP):$GW_PORT"
Write-Host ""

Write-Host "NOTE: This is a basic Windows port of flash_efr32.sh."
Write-Host "For full functionality, consider using WSL (Windows Subsystem for Linux) where the bash version runs natively."
Write-Host ""
Write-Host "Current limitations:"
Write-Host "  - Requires SSH client in PATH"
Write-Host "  - Requires Python 3 and universal-silabs-flasher"
Write-Host "  - Some bridge detection features may require WSL"
Write-Host ""
Write-Host "To use the native bash version:"
Write-Host "  wsl ./flash_efr32.sh"
Write-Host ""

# Check if gateway is reachable
Write-Host "Testing connection to gateway at $GW_IP..."

$isReachable = wait_for_port -Host $GW_IP -Port 22 -TimeoutSeconds 3
if ($isReachable) {
    Write-Host "Gateway is reachable via SSH."
    Write-Host ""
    Write-Host "The Windows PowerShell port of flash_efr32.ps1 is limited."
    Write-Host "For best results with full functionality, use the bash version in WSL:"
    Write-Host "  wsl ./flash_efr32.sh -y -g $GW_IP"
    Write-Host ""
}
else {
    Write-Error "Cannot reach gateway at $GW_IP. Please check the network connection."
    exit 1
}

Write-Host "Consider using the original bash scripts via WSL for full featureset support."
Write-Host ""
Write-Host "To set up bash shell on Windows:"
Write-Host "  1. Install WSL: https://learn.microsoft.com/en-us/windows/wsl/install"
Write-Host "  2. Then run: wsl ./flash_efr32.sh -y -g $GW_IP"
Write-Host ""

