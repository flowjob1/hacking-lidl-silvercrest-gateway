# lib\ssh.ps1 — common SSH helpers for the flash_*.ps1 scripts.
#
# Sourced by:
#   - flash_efr32.ps1                                (repo root)
#   - flash_install_rtl8196e.ps1                     (repo root)
#
# Provides hardened SSH options that prevent the "ssh hangs forever after
# the gateway reboots" failure mode observed during v3.1 testing, plus a
# retry-on-transport-failure helper.

# Hardened SSH options (PowerShell hashtable - splat into ssh invocation)
$SSH_HARDEN_OPTS = @(
    '-o', 'ConnectTimeout=5'
    '-o', 'ServerAliveInterval=5'
    '-o', 'ServerAliveCountMax=5'
    '-o', 'BatchMode=yes'
    '-o', 'StrictHostKeyChecking=accept-new'
    '-o', 'UserKnownHostsFile=$HOME\.ssh\known_hosts'
)

# ssh_retry: ssh wrapper that retries on transport failures only (rc=255).
# Real remote-command exit codes pass through unchanged so callers can
# branch on them.
#
# Usage:  ssh_retry @()ssh_args target command...
#
# Example:
#   ssh_retry -SSHArgs $SSH_HARDEN_OPTS -Target "root@$GW_IP" -Command "uptime"
function ssh_retry {
    param(
        [string[]]$SSHArgs = @(),
        [string]$Target,
        [string]$Command
    )

    $maxAttempts = 3
    $attempt = 1

    while ($attempt -le $maxAttempts) {
        if ($DEBUG -eq 'y') {
            Write-Host "[DEBUG] SSH attempt $attempt : ssh $($SSHArgs -join ' ') $Target $Command" -ForegroundColor Cyan >&2
        }

        $sshArgs = @($SSHArgs) + @($Target) + @($Command)

        & ssh @sshArgs
        $rc = $LASTEXITCODE

        if ($DEBUG -eq 'y') {
            Write-Host "[DEBUG] SSH attempt $attempt returned: $rc" -ForegroundColor Cyan >&2
        }

        # rc=255 is SSH's "transport failed" code (cannot connect, host
        # unreachable, connection dropped mid-flight). Anything else is
        # the real remote command exit code — never retry that.
        if ($rc -ne 255) {
            return $rc
        }

        if ($attempt -lt 3) {
            $sleepTime = $attempt * 2
            Write-Warning "SSH transport failed (attempt $attempt/3); retrying in ${sleepTime}s..."
            Start-Sleep -Seconds $sleepTime
        }

        $attempt++
    }

    Write-Error "SSH failed after 3 attempts."
    return 43
}

# wait_for_port: poll a TCP port until it accepts a connection or timeout.
# Useful after a kernel-bridge baud change (port closes briefly) or after
# a gateway reboot.
function wait_for_port {
    param(
        [string]$Host,
        [int]$Port,
        [int]$TimeoutSeconds = 5
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    if ($DEBUG -eq 'y') {
        Write-Host "[DEBUG] Waiting for $Host :$Port (timeout: ${TimeoutSeconds}s)" -ForegroundColor Cyan >&2
    }

    while ((Get-Date) -lt $deadline) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.ConnectAsync($Host, $Port).Wait(1000) | Out-Null

            if ($tcpClient.Connected) {
                $tcpClient.Close()
                if ($DEBUG -eq 'y') {
                    Write-Host "[DEBUG] Port $Host :$Port is reachable" -ForegroundColor Cyan >&2
                }
                return $true
            }
        }
        catch {
            # Connection failed, continue
        }
        finally {
            if ($tcpClient) { $tcpClient.Dispose() }
        }

        Start-Sleep -Milliseconds 500
    }

    if ($DEBUG -eq 'y') {
        Write-Host "[DEBUG] Port $Host :$Port not reachable after ${TimeoutSeconds}s" -ForegroundColor Cyan >&2
    }
    return $false
}

# Export functions
Export-ModuleMember -Function @('ssh_retry', 'wait_for_port') -Variable @('SSH_HARDEN_OPTS')

