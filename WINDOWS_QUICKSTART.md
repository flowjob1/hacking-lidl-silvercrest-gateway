# Windows-Benutzer Quick-Start

Wenn du von Windows aus arbeiten möchtest, sind hier die wichtigsten Informationen:

## TL;DR - Schnelleinstieg

### Option 1: Batch-Wrapper (Einfach)

```cmd
REM Im CMD oder PowerShell
backup_gateway.cmd --linux-ip 192.168.1.88
flash_efr32.cmd -y ncp
flash_install_rtl8196e.cmd 192.168.1.88
```

### Option 2: WSL (Empfohlen - Beste Kompatibilität)

```powershell
# PowerShell als Administrator
wsl --install

# Nach Neustart, dann direkt die Bash-Skripte verwenden
wsl ./backup_gateway.sh --linux-ip 192.168.1.88
wsl ./flash_efr32.sh -y ncp
wsl ./flash_install_rtl8196e.sh 192.168.1.88
```

### Option 3: PowerShell Makefile

```powershell
# PowerShell
.\Makefile.ps1 -Command backup
.\Makefile.ps1 -Command flash-efr32 -Arguments "-y", "ncp"
.\Makefile.ps1 -Command flash-install -Arguments "192.168.1.88"
```

## Was wurde für Windows portiert?

| Original | Windows Version | Typ | Status |
|----------|-----------------|-----|--------|
| `lib/ssh.sh` | `lib/ssh.ps1` | PowerShell | Experimentell |
| `backup_gateway.sh` | `backup_gateway.ps1` + `backup_gateway.cmd` | PS1 + Batch | Funktionell / Wrapper |
| `flash_efr32.sh` | `flash_efr32.ps1` + `flash_efr32.cmd` | PS1 + Batch | Funktionell / Wrapper |
| `flash_install_rtl8196e.sh` | `flash_install_rtl8196e.ps1` + `.cmd` | PS1 + Batch | Funktionell / Wrapper |

## Anforderungen

### Für Batch-Wrapper (`.cmd` Dateien):

Benötigt **eine** der folgenden:
- **WSL** (empfohlen)
- **Git Bash**
- **MSYS2**

### Für PowerShell-Skripte (`.ps1` Dateien):

- PowerShell 5.0+
- Als Administrator ausführen (`Set-ExecutionPolicy`)
- SSH Client in PATH
- (Optional) Python 3 für erweiterte Features

### Für maximale Kompatibilität:

- **WSL** (alle Tools natürlich verfügbar)

## Installation Schritt-für-Schritt

### Schritt 1: WSL installieren (empfohlen)

```powershell
# PowerShell als Administrator starten
wsl --install
```

Dann Computer neustarten.

### Schritt 2 (Falls kein WSL): Git Bash oder SSH

Falls WSL nicht gewünscht, installiere eine Alternative:

```powershell
# Option A: Git Bash (beliebt, einfach)
# Besuche: https://git-scm.com/download/win

# Option B: Windows OpenSSH
# Siehe: https://docs.microsoft.com/en-us/windows-server/administration/openssh/

# Option C: MSYS2
# Besuche: https://www.msys2.org/
```

### Schritt 3: Skripte ausführen

```cmd
REM Erste Sicherung
backup_gateway.cmd --linux-ip 192.168.1.88

REM EFR32 flashen
flash_efr32.cmd -y ncp

REM Main-Firmware installieren
flash_install_rtl8196e.cmd 192.168.1.88
```

## Beispiele

### Sicherung durchführen

```cmd
REM Standardgateway (192.168.1.88)
backup_gateway.cmd

REM Andere IP
backup_gateway.cmd --linux-ip 10.0.0.88

REM Mit benutzerdefiniertem Ausgabeverzeichnis
backup_gateway.cmd --output C:\backups\my-gateway
```

### EFR32 Zigbee-Radio flashen

```cmd
REM Interaktives Menü
flash_efr32.cmd

REM Automatisch NCP @ 115200
flash_efr32.cmd -y ncp

REM OT-RCP @ 460800 auf custom IP
flash_efr32.cmd -y -g 10.0.0.88 otrcp 460800

REM Mit Debug-Output
set DEBUG=y
flash_efr32.cmd -y -g 192.168.1.88 ncp
```

### Hauptfirmware (RTL8196E) installieren

```cmd
REM Upgrade (mit Sicherung)
flash_install_rtl8196e.cmd -y 192.168.1.88

REM Erste Installation (Bootloader-Modus)
flash_install_rtl8196e.cmd
```

## Häufige Probleme

### Problem: "bash: command not found"

**Lösung:**
- Installiere WSL, Git Bash oder MSYS2
- Stelle sicher, dass sie im PATH sind

### Problem: "ssh: command not found"

**Lösung:**
- Ubuntu/Linux auf WSL: Läuft bereits nativ
- Windows: Installiere OpenSSH oder Git Bash

### Problem: "tftp: command not found"

**Lösung:**
- Windows 10/11: `Systemsteuerung > Windows-Features > TFTP-Client aktivieren`
- Oder: `dism /online /Enable-Feature /FeatureName:TFTP`

### Problem: ".cmd-Datei wird nicht ausgeführt"

**Lösung:**
```powershell
# PowerShell als Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Dann neu versuchen.

### Problem: PowerShell-Skript wird nicht ausgeführt

**Lösung:**
```powershell
# PowerShell als Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Dann ausführen
.\Makefile.ps1 -Command help
```

## Umgebungsvariablen

Für automatische Konfiguration (CMD):

```cmd
REM In CMD oder PowerShell CMD-Syntax
set LINUX_IP=192.168.1.88
set BOOT_IP=192.168.1.6
set DEBUG=y

REM Dann Skripte aufrufen
backup_gateway.cmd
```

Für PowerShell:

```powershell
$env:LINUX_IP = "192.168.1.88"
$env:DEBUG = "y"

.\backup_gateway.ps1
```

## Fehlerbehandlung

### Im Fehlerfall:

1. **Konsole mit Admin-Rechten starten**
2. **Debug-Output aktivieren**:
   ```cmd
   set DEBUG=y
   backup_gateway.cmd --linux-ip 192.168.1.88
   ```
3. **Checklist**:
   - Ist das Netzwerk-Kabel angesteckt?
   - Ist die Gateway-IP korrekt (`192.168.1.88`)?
   - Kann der Computer das Gateway erreichen? (`ping 192.168.1.88`)

## Für Entwickler

### Neue Skripte hinzufügen

1. Bash-Version: `something.sh`
2. PowerShell-Version: `something.ps1` (oder übergeben zu WSL)
3. Batch-Wrapper: `something.cmd` (WSL-Autodetect)

### Testing

```cmd
REM Testen mit WSL direkt
wsl ./flash_efr32.sh --help

REM Testen mit Batch-Wrapper
flash_efr32.cmd --help

REM Testen mit PowerShell
.\flash_efr32.ps1 -Help
```

## Weitere Informationen

- Detaillierte Anleitung: Siehe `WINDOWS_PORTING.md`
- Original README: `README.md`
- Architektur: `3-Main-SoC-Realtek-RTL8196E/README.md`

## Zusammenfassung

Windows-Portierung mit drei Ebenen:

| Methode | Aufwand | Kompatibilität | Empfohlene Nutzung |
|---------|---------|----------------|--------------------|
| Batch-Wrapper (`.cmd`) | Minimal | Gut - Wrapper | **Einfacher Einstieg** |
| WSL direkt | Minimal (nach WSL-Install) | Perfekt | **Best Practice** |
| PowerShell (`.ps1`) | Komplex | Begrenzt | Experimentell |

---

Haben Sie Fragen? → Lesen Sie `WINDOWS_PORTING.md` für detaillierte Informationen.

