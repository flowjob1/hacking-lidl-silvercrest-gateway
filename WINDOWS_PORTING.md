# Windows Portierung: Flash- und Backup-Skripte

Diese Dokumentation beschreibt, wie die Flash- und Backup-Skripte unter Windows verwendet werden können.

## Zusammenfassung

Die Kernlogik der bash-Skripte wurde auf Windows portiert. Es gibt mehrere Ansätze:

### 1. **Empfohlen: WSL + Batch-Wrapper** 
Beste Kompatibilität - verwendet automatisch WSL wenn verfügbar.

```cmd
# Windows CMD
backup_gateway.cmd [--linux-ip IP] [--boot-ip IP] [--output DIR]
flash_efr32.cmd [-y] [FIRMWARE] [BAUD]
flash_install_rtl8196e.cmd [-y] [LINUX_IP]
```

### 2. **WSL direkt aufrufen**
Verwende die Bash-Skripte direkt vom WSL-Terminal:

```bash
wsl ./backup_gateway.sh --linux-ip 192.168.1.88
wsl ./flash_efr32.sh -y -g 192.168.1.88 ncp
wsl ./flash_install_rtl8196e.sh 192.168.1.88
```

### 3. **PowerShell-Versionen** (begrenzte Funktionalität)
Nur für Basis-Operationen; PowerShell-Versionen sind vorhanden für experimentelle Zwecke:

```powershell
# PowerShell
.\backup_gateway.ps1 -LinuxIP 192.168.1.88
.\flash_efr32.ps1 -y -GatewayIP 192.168.1.88 -FirmwareType ncp
.\flash_install_rtl8196e.ps1 -LinuxIP 192.168.1.88 -Yes
```

## Installation auf Windows

### Option A: WSL (Empfohlen)

WSL ermöglicht die unveränderte Nutzung der Original-Bash-Skripte und ist optimal für Entwicklung:

1. **WSL installieren** (Windows 10/11 Version 2004+):

```powershell
# PowerShell als Administrator ausführen
wsl --install
```

2. **Ubuntu distributions wählen** beim ersten Start

3. **Im WSL-Terminal arbeiten**:

```bash
# In WSL-Terminal
cd /mnt/c/path/to/hacking-lidl-silvercrest-gateway

# Bash-Skripte nutzen (original, volle Funktionalität)
./backup_gateway.sh --linux-ip 192.168.1.88
./flash_efr32.sh -y -g 192.168.1.88
./flash_install_rtl8196e.sh 192.168.1.88
```

### Option B: Git Bash

Reduzierte Funktionalität, aber einfache Installation:

1. [Git Bash installieren](https://git-scm.com/download/win)

2. Im Git Bash-Terminal nutzen:

```bash
./backup_gateway.sh [options]
./flash_efr32.sh [options]
./flash_install_rtl8196e.sh [options]
```

### Option C: Windows CMD + Automatische WSL/Git Bash-Erkennung

Batch-Wrapper automatisieren die Shell-Auswahl:

```cmd
REM In PowerShell oder CMD
backup_gateway.cmd --linux-ip 192.168.1.88
flash_efr32.cmd -y ncp
flash_install_rtl8196e.cmd 192.168.1.88
```

Die `.cmd` Dateien:
- Prüfen zuerst nach WSL (`wsl` Befehl)
- Fallen auf Git Bash (`C:\Program Files\Git\bin\bash.exe`) zurück
- Zeigen Installationsanleitung, wenn keine Shell gefunden

### Option D: PowerShell-Skripte

Für PowerShell-native Skripte (experimentell, begrenzt):

```powershell
# PowerShell als Administrator ausführen
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.\backup_gateway.ps1 -LinuxIP 192.168.1.88
.\flash_efr32.ps1 -y ncp
.\flash_install_rtl8196e.ps1 -LinuxIP 192.168.1.88
```

Die PowerShell-Versionen haben eingeschränkte Funktionalität und empfehlen die Nutzung von WSL.

## Verfügbare Dateien

| Datei | Typ | Funktion | Best Practice |
|-------|-----|----------|-------|
| `lib/ssh.sh` | Bash | SSH-Hilfsfunktionen | Original bash |
| `lib/ssh.ps1` | PowerShell | SSH-Hilfsfunktionen | Experimentell |
| `lib/ssh.cmd` | Batch | SSH-Hinweis | Info-Datei |
| `backup_gateway.sh` | Bash | Gateway-Daten sichern | Original bash / WSL |
| `backup_gateway.ps1` | PowerShell | Gateway-Daten sichern (Windows) | Begrenzt |
| `backup_gateway.cmd` | Batch | WSL/Git Bash-Wrapper | **Empfohlen** |
| `flash_efr32.sh` | Bash | EFR32 flashen | Original bash / WSL |
| `flash_efr32.ps1` | PowerShell | EFR32 flashen (Windows) | Begrenzt |
| `flash_efr32.cmd` | Batch | WSL/Git Bash-Wrapper | **Empfohlen** |
| `flash_install_rtl8196e.sh` | Bash | RTL-Firmware installieren | Original bash / WSL |
| `flash_install_rtl8196e.ps1` | PowerShell | RTL-Firmware installieren (Windows) | Begrenzt |
| `flash_install_rtl8196e.cmd` | Batch | WSL/Git Bash-Wrapper | **Empfohlen** |

## Nutzungsbeispiele

### Backup über Windows CMD

```cmd
REM Mit WSL-Wrapper
backup_gateway.cmd --linux-ip 192.168.1.88

REM Oder mit PowerShell
powershell .\backup_gateway.ps1 -LinuxIP 192.168.1.88

REM Oder mit WSL direkt
wsl ./backup_gateway.sh --linux-ip 192.168.1.88
```

### EFR32 flashen über Windows PowerShell

```powershell
# Standard Gateway-IP
.\flash_efr32.ps1 -y ncp

# Benutzerdefinierte IP
.\flash_efr32.ps1 -y -GatewayIP 10.0.0.5 otrcp

# Mit Debug-Output
.\flash_efr32.ps1 -y -Debug -GatewayIP 192.168.1.88 ncp 460800
```

### Firmware installieren über CMD mit WSL-Wrapper

```cmd
# Mit bestehendem Linux-System
flash_install_rtl8196e.cmd -y 192.168.1.88

# Erste Installation (Bootloader-Modus)
flash_install_rtl8196e.cmd
```

## Wichtige Unterschiede Windows vs. Linux

| Feature | Linux/WSL | Windows (PowerShell) | Windows (CMD/WSL) |
|---------|-----------|-------------------|-------------------|
| SSH | Nativ | Nativ (OpenSSH) | Nativ |
| TFTP | tftp-hpa | Begrenzte Unterstützung | tftp |
| Netzwerk-Tools | ip, arp, ping | ipconfig, arp, ping | Über WSL |
| Datei-Operationen | find, grep, awk | PowerShell-Äquivalente | Bash-Tools |
| Prozess-Management | Standard | Start-Process | Bash |
| Pfade | Unix-Stil | Windows/Backslash | Beide |

## Fehlerbehebung

### Problem: "ssh command not found"

**Lösung:**
1. OpenSSH für Windows [installieren](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)
2. Oder Git Bash installieren
3. Oder WSL verwenden

### Problem: "tftp command not found"

**Lösung:**
- In Windows 10/11: `tftp` ist in den meisten Standard-Installationen enthalten
- Falls nicht: `Systemsteuerung > Programme > Windows-Features > TFTP-Client`
- Oder: `dism /online /Enable-Feature /FeatureName:TFTP`

### Problem: PowerShell-Skripte laufen nicht

**Lösung:**
```powershell
# Führe PowerShell als Administrator aus
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: WSL nicht gefunden

**Lösung:**
```powershell
# PowerShell als Administrator
wsl --install
```

Nach Installation den PC neustarten und neu versuchen.

## Best Practices

### 1. **Nutze WSL für vollständige Kompatibilität**

```bash
# Schnell und zuverlässig
wsl ./flash_efr32.sh -y ncp
```

### 2. **Verwende die `.cmd` Wrapper für Portabilität**

```cmd
REM Funktioniert mit oder ohne WSL/Git Bash
backup_gateway.cmd --linux-ip 192.168.1.88
```

### 3. **Backup vor dem Flashen!**

```cmd
REM Sicherung vorab
backup_gateway.cmd --linux-ip 192.168.1.88 --output C:\backups\gateway-backup
```

### 4. **Debug-Modus für Fehlerbehebung**

```cmd
REM Mit Debug-Output
wsl ./flash_efr32.sh -d -y -g 192.168.1.88 ncp
```

## Konfiguration

Umgebungsvariablen können gesetzt werden:

```powershell
# PowerShell
$env:LINUX_IP = "192.168.1.88"
$env:BOOT_IP = "192.168.1.6"
$env:DEBUG = "y"
.\backup_gateway.ps1

# CMD
set LINUX_IP=192.168.1.88
set BOOT_IP=192.168.1.6
set DEBUG=y
backup_gateway.cmd
```

## Zusammenfassung der Portierungsstrategie

**Drei Ansätze für Windows-Kompatibilität:**

1. **Wrapper .cmd-Dateien** — Automatische Shell-Erkennung, einfach zu verwenden
2. **WSL-Fallback** — Nutzt den "echten" Linux-Code, beste Kompatibilität
3. **PowerShell-Alternativen** — Experimentell, für Limited-Resource-Szenarien

**Empfohlene Reihenfolge:**

```
Ausprobieren → .cmd-Wrapper → WSL direkter Aufruf → PowerShell (als letzter Ausweg)
```

---

**Fragen oder Probleme?** → Nutzung von WSL ist die zuverlässigste Option für alle Betriebssysteme.

