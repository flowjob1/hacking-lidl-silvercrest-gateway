# backup_gateway.ps1 — Unified backup script for Lidl Silvercrest Gateway (Windows version)
#
# Detects the gateway state (custom Linux, Tuya Linux, or bootloader) and
# chooses the best backup method automatically. Never modifies the system.
#
# Usage: .\backup_gateway.ps1 [--linux-ip IP] [--boot-ip IP] [--output DIR] [--help]
#
# Required: SSH client (OpenSSH or compatible), available in PATH
#
# J. Nilo - March 2026, Windows port April 2026

param(
    [string]$LinuxIP = $env:LINUX_IP,
    [string]$BootIP = $env:BOOT_IP,
    [string]$OutputDir = $env:BACKUP_DIR,
    [string]$SSHUser = $env:SSH_USER,
    [switch]$Help,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path (Resolve-Path $PSCommandPath)
$splitFlash = Join-Path $scriptDir "3-Main-SoC-Realtek-RTL8196E\30-Backup-Restore\split_flash.sh"

# Defaults
if (-not $LinuxIP) { $LinuxIP = "192.168.1.88" }
if (-not $BootIP) { $BootIP = "192.168.1.6" }
if (-not $SSHUser) { $SSHUser = "root" }
$FLASH_SIZE = 16 * 1024 * 1024  # 16 MiB

if ($Help) {
    Write-Host @"
Usage: $($MyInvocation.MyCommand.Name) [--linux-ip IP] [--boot-ip IP] [--output DIR] [--help]

Detects gateway state and backs up all flash partitions.

Options:
  --linux-ip IP   Gateway IP under Linux (default: 192.168.1.88)
  --boot-ip  IP   Gateway IP in bootloader (default: 192.168.1.6)
  --output   DIR  Output directory (default: .\backups\YYYYMMDD-HHMM)
  --help          Show this help and exit

Environment variables: LINUX_IP, BOOT_IP, BACKUP_DIR, SSH_USER
"@
    exit 0
}

# Check for SSH
$sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshCmd) {
    Write-Error "SSH client not found. Install OpenSSH for Windows or use WSL."
    exit 1
}

# Create output directory
if (-not $OutputDir) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $OutputDir = Join-Path $scriptDir "backups\$timestamp"
}

New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

# Start logging
$logFile = Join-Path $OutputDir "backup.log"
Start-Transcript -Path $logFile -Append | Out-Null

try {
    Write-Host "========================================="
    Write-Host "  GATEWAY BACKUP"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "Linux IP:    $LinuxIP"
    Write-Host "Boot IP:     $BootIP"
    Write-Host "Output:      $OutputDir"
    Write-Host ""

    # Check if SSH port is open
    function Test-SSHPort {
        param([string]$IP, [int]$Port)

        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.ConnectAsync($IP, $Port).Wait(2000) | Out-Null
            $result = $tcpClient.Connected
            $tcpClient.Close()
            return $result
        }
        catch {
            return $false
        }
    }

    # Detect gateway state based on SSH availability
    Write-Host "Detecting gateway state..."

    $state = $null
    if (Test-SSHPort $LinuxIP 22) {
        $state = "custom_linux"
    }
    elseif (Test-SSHPort $LinuxIP 2333) {
        $state = "tuya_linux"
    }
    else {
        Write-Error "Cannot reach gateway ($LinuxIP). No SSH on port 22 (custom) or 2333 (Tuya)."
        exit 1
    }

    Write-Host "State: $state"
    Write-Host ""

    # Back up via SSH
    function Backup-ViaSsh {
        param(
            [int]$SSHPort
        )

        $sshOpts = @(
            '-p', $SSHPort
            '-o', 'HostKeyAlgorithms=+ssh-rsa'
            '-o', 'StrictHostKeyChecking=no'
            '-o', 'UserKnownHostsFile=$env:USERPROFILE\.ssh\known_hosts'
            '-o', 'ConnectTimeout=10'
            '-o', 'ControlMaster=auto'
            '-o', 'ControlPersist=60'
        )

        Write-Host "Connecting to $($LinuxIP) :$SSHPort..."

        $target = "$SSHUser@$LinuxIP"
        $procMtd = & ssh @sshOpts $target "cat /proc/mtd"

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Cannot connect to $LinuxIP :$SSHPort"
            exit 1
        }

        write-Host $procMtd
        Write-Host ""

        # Parse partitions
        $mtdDevs = @()
        $mtdNames = @()
        $mtdSizes = @()

        $procMtd | Select-Object -Skip 1 | ForEach-Object {
            if ($_ -match '^(\w+):\s+([0-9a-f]+)\s+\w+\s+"(.+)"') {
                $mtdDevs += $Matches[1]
                $mtdNames += $Matches[3]
                $mtdSizes += [Convert]::ToInt32($Matches[2], 16)
            }
        }

        $nParts = $mtdDevs.Count
        Write-Host "Found $nParts partitions."
        Write-Host ""

        # Dump each partition
        for ($i = 0; $i -lt $nParts; $i++) {
            $dev = $mtdDevs[$i]
            $name = $mtdNames[$i]
            $expected = $mtdSizes[$i]
            $outfile = Join-Path $OutputDir "$($dev)_$name.bin"

            Write-Host "Dumping $dev ($name, $expected bytes)..."

            $remoteOut = & ssh @sshOpts $target "cat /dev/$dev" | Set-Content -Path $outfile -Encoding Byte -NoNewline

            $actual = (Get-Item $outfile).Length
            $status = if ($actual -eq $expected) { "[OK]" } else { "[MISMATCH]" }
            Write-Host "  $($dev)_$($name).bin: $actual bytes $status"
        }

        # Concatenate into fullflash.bin
        Write-Host ""
        Write-Host "Creating fullflash.bin..."

        $concatFiles = @()
        for ($i = 0; $i -lt $nParts; $i++) {
            $concatFiles += Join-Path $OutputDir "$($mtdDevs[$i])_$($mtdNames[$i]).bin"
        }

        $fullflashPath = Join-Path $OutputDir "fullflash.bin"
        $fs = [System.IO.File]::Create($fullflashPath)

        foreach ($file in $concatFiles) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $fs.Write($bytes, 0, $bytes.Length)
        }

        # Pad to 16 MB if needed
        $currentSize = $fs.Length
        if ($currentSize -lt $FLASH_SIZE) {
            $pad = $FLASH_SIZE - $currentSize
            Write-Host "Padding fullflash.bin with $pad bytes (0xFF) to reach 16 MiB..."
            $paddingBytes = [byte[]]::new($pad)
            [Array]::Fill($paddingBytes, [byte]0xFF)
            $fs.Write($paddingBytes, 0, $paddingBytes.Length)
        }

        $fs.Close()
    }

    switch ($state) {
        "custom_linux" {
            Write-Host "Backing up via SSH (port 22, custom firmware)..."
            Write-Host ""
            Backup-ViaSsh -SSHPort 22
        }
        "tuya_linux" {
            Write-Host "Backing up via SSH (port 2333, Tuya firmware)..."
            Write-Host ""
            Backup-ViaSsh -SSHPort 2333
        }
    }

    # Verify
    Write-Host ""
    Write-Host "========================================="
    Write-Host "  VERIFICATION"
    Write-Host "========================================="
    Write-Host ""

    $fullflashFile = Join-Path $OutputDir "fullflash.bin"
    if (Test-Path $fullflashFile) {
        $size = (Get-Item $fullflashFile).Length
        if ($size -eq $FLASH_SIZE) {
            $md5 = (Get-FileHash $fullflashFile -Algorithm MD5).Hash
            Write-Host "fullflash.bin: $size bytes (16 MiB) [OK]"
            Write-Host "MD5: $md5"
        }
        else {
            Write-Warning "fullflash.bin: $size bytes [EXPECTED: $FLASH_SIZE] [MISMATCH]"
        }
    }
    else {
        Write-Warning "fullflash.bin not found."
    }

    Write-Host ""
    Write-Host "Backup files:"
    Get-ChildItem -Path $OutputDir -Filter "*.bin" | ForEach-Object { Write-Host "  $($_.Name) ($([int]$_.Length / 1MB) MiB)" }
    Write-Host ""
    Write-Host "Log: $logFile"
    Write-Host ""
    Write-Host "Backup complete."
}
finally {
    Stop-Transcript | Out-Null
}

