# Windows Portierung - Übersicht der neuen Dateien

Diese Datei dokumentiert alle für die Windows-Kompatibilität erstellten oder angepassten Dateien.

## Neu erstellte Dateien

### Dokumentation (Markdown)

| Datei | Beschreibung |
|-------|-------------|
| `WINDOWS_PORTING.md` | Detaillierte technische Anleitung zur Windows-Portierung |
| `WINDOWS_QUICKSTART.md` | Quick-Start-Anleitung für Windows-Benutzer (empfohlen zuerst lesen) |
| `WINDOWS_PORTING_OVERVIEW.md` | Diese Datei |

### PowerShell-Skripte (`.ps1`)

Experimentelle PowerShell-Versionen mit Windows-nativen Tools:

| Datei | Basis | Funktion | Status |
|-------|-------|----------|--------|
| `lib/ssh.ps1` | `lib/ssh.sh` | SSH-Hilfsfunktionen | Experimentell |
| `backup_gateway.ps1` | `backup_gateway.sh` | Gateway-Backup | Begrenzt funktionsfähig |
| `flash_efr32.ps1` | `flash_efr32.sh` | EFR32-Flashing | Begrenzt (empfiehlt WSL) |
| `flash_install_rtl8196e.ps1` | `flash_install_rtl8196e.sh` | RTL-Installation | Begrenzt (empfiehlt WSL) |

### Batch-Wrapper (`.cmd`)

Automatische Shell-Erkennung mit WSL/Git-Bash Fallback:

| Datei | Basis | Zweck |
|-------|-------|--------|
| `backup_gateway.cmd` | `lib/ssh.sh` → bash | WSL/Git Bash Auto-Wrapper |
| `flash_efr32.cmd` | `flash_efr32.sh` | WSL/Git Bash Auto-Wrapper |
| `flash_install_rtl8196e.cmd` | `flash_install_rtl8196e.sh` | WSL/Git Bash Auto-Wrapper |
| `lib/ssh.cmd` | `lib/ssh.sh` | Info-Datei (Verweislink) |

### Quick-Start Tools

| Datei | Typ | Zweck |
|-------|-----|--------|
| `Makefile.bat` | Batch | Schnelle Kommandos im CMD |
| `Makefile.ps1` | PowerShell | Schnelle Kommandos im PS |

## Empfohlene Nutzungswege

### Für schnelle Einsteiger 🚀

```
1. Falls noch nicht vorhanden: WSL installieren
   https://learn.microsoft.com/en-us/windows/wsl/install

2. Dann in Windows-Terminal/PowerShell nutzen:
   wsl ./flash_efr32.sh -y ncp
   wsl ./backup_gateway.sh --linux-ip 192.168.1.88
```

### Für Windows CMD-Benutzer

```
backup_gateway.cmd --linux-ip 192.168.1.88
flash_efr32.cmd -y ncp
flash_install_rtl8196e.cmd 192.168.1.88
```

Die `.cmd`-Dateien erkennen automatisch WSL oder Git Bash.

### Für PowerShell-Profis

```powershell
# Option 1: Makefile.ps1 nutzen
.\Makefile.ps1 -Command backup

# Option 2: Direkt PowerShell-Skripte (experimentell)
.\backup_gateway.ps1 -LinuxIP 192.168.1.88
```

## Architektur der Portierung

```
┌─ Original Bash-Skripte (optimal, getestet)
│   ├── flash_efr32.sh
│   ├── backup_gateway.sh
│   └── flash_install_rtl8196e.sh
│
├─ Wrapper für Windows (auto-detection)
│   ├── flash_efr32.cmd ─→ ruft bash auf
│   ├── backup_gateway.cmd ─→ ruft bash auf
│   └── flash_install_rtl8196e.cmd ─→ ruft bash auf
│
├─ PowerShell-Implementierungen (experimentell)
│   ├── flash_efr32.ps1 (Windows-native)
│   ├── backup_gateway.ps1 (Windows-native)
│   └── flash_install_rtl8196e.ps1 (Windows-native)
│
└─ Tools und Dokumentation
    ├── Makefile.bat (CMD-Wrapper)
    ├── Makefile.ps1 (PS-Wrapper)
    ├── WINDOWS_PORTING.md (detailliert)
    └── WINDOWS_QUICKSTART.md (einsteigerfreundlich)
```

## Kompatibilität Pro Betriebssystem

### Windows 10/11 mit WSL (EMPFOHLEN)

| Tool | Status | Anmerkung |
|------|--------|-----------|
| SSH | ✅ Funktionsfähig | Linux-native OpenSSH |
| TFTP | ✅ Funktionsfähig | Linux-native tftp |
| Python | ✅ Funktionsfähig | Linux-native Python |
| Netzwerk-Tools | ✅ Vollständig | Linux-native ip, arp, etc. |
| **Skripte** | ✅ **Perfekt** | Original bash - volle Kompatibilität |

**Empfehlung:** Nutze `wsl ./flash_efr32.sh` direkt

### Windows 10/11 mit Git Bash

| Tool | Status | Anmerkung |
|------|--------|-----------|
| SSH | ✅ Funktionsfähig | Git-Bundle OpenSSH |
| TFTP | ⚠️ Begrenzt | Manuell zu installieren |
| Python | ✅ Funktionsfähig | Separat installiert |
| Netzwerk-Tools | ⚠️ Begrenzt | grep/awk OK, aber nicht alle Tools |
| **Skripte** | ✅ **Meist OK** | Bash-Kompatibilität gut |

**Empfehlung:** Nutze `.cmd` Wrapper oder Git Bash direkt

### Windows (nur CMD/PowerShell)

| Tool | Status | Anmerkung |
|------|--------|-----------|
| SSH | ✅ Funktionsfähig | Windows-OpenSSH nötig |
| TFTP | ⚠️ Systemabhängig | Oft deaktiviert |
| Python | ✅ Funktionsfähig | Separat installiert |
| Netzwerk-Tools | ⚠️ Begrenzt | ipconfig, arp funktionieren |
| **Skripte** | ❌ **Nicht möglich** | Keine bash verfügbar |

**Empfehlung:** WSL installieren oder PowerShell-Versionen nutzen (begrenzt)

## Datei-Struktur nach Portierung

```
hacking-lidl-silvercrest-gateway/
├── README.md                           (ursprünglich)
│
├── flash_efr32.sh                      (ursprüngliches Bash-Skript)
├── flash_efr32.cmd                     ← NEU: Windows Wrapper
├── flash_efr32.ps1                     ← NEU: PowerShell-Version
│
├── backup_gateway.sh                   (ursprüngliches Bash-Skript)
├── backup_gateway.cmd                  ← NEU: Windows Wrapper
├── backup_gateway.ps1                  ← NEU: PowerShell-Version
│
├── flash_install_rtl8196e.sh           (ursprüngliches Bash-Skript)
├── flash_install_rtl8196e.cmd          ← NEU: Windows Wrapper
├── flash_install_rtl8196e.ps1          ← NEU: PowerShell-Version
│
├── Makefile.bat                        ← NEU: CMD Quick-Start
├── Makefile.ps1                        ← NEU: PowerShell Quick-Start
│
├── WINDOWS_PORTING.md                  ← NEU: Detaillierte Anleitung
├── WINDOWS_QUICKSTART.md               ← NEU: Einsteigeranleitung
├── WINDOWS_PORTING_OVERVIEW.md         ← NEU: Diese Datei
│
├── lib/
│   ├── ssh.sh                          (ursprünglich)
│   ├── ssh.ps1                         ← NEU: PowerShell-Version
│   └── ssh.cmd                         ← NEU: Info-Wrapper
│
└── ... (andere Dateien unverändert)
```

## Migration vom Linux zum Windows Workflow

### Vorher (nur Linux/WSL)

```bash
# Nur mit native bash möglich
./backup_gateway.sh --linux-ip 192.168.1.88
./flash_efr32.sh -y ncp
./flash_install_rtl8196e.sh 192.168.1.88
```

### Nachher (Windows + Linux)

```cmd
REM Windows CMD / PowerShell

# Option 1: Über Wrapper (Auto-Detection)
backup_gateway.cmd --linux-ip 192.168.1.88
flash_efr32.cmd -y ncp
flash_install_rtl8196e.cmd 192.168.1.88

# Option 2: Direkt WSL konfiguriert für PowerShell
wsl ./backup_gateway.sh --linux-ip 192.168.1.88
wsl ./flash_efr32.sh -y ncp

# Option 3: PowerShell-Makefile
.\Makefile.ps1 -Command backup
.\Makefile.ps1 -Command flash-efr32 -Arguments "-y", "ncp"
```

## Bedeutende Unterschiede

### Bash vs. PowerShell Syntax

| Konzept | Bash | PowerShell |
|---------|------|-----------|
| Variablen | `$var` | `$var` |
| Arrays | `(1 2 3)` | `@(1, 2, 3)` |
| Funktionen | `func() {}` | `function func {}` |
| Pipes | `\|` | `\|` (ähnlich) |
| Fehlerbehandlung | `$?` / `$!` | `$?` / `$Error` |

### Linux vs. Windows Pfade

| Operation | Linux | Windows (PowerShell) |
|-----------|-------|------------|
| Aktuelles Verzeichnis | `./` | `.\` |
| Temp-Dateien | `/tmp/` | `$env:TEMP` |
| Home-Verzeichnis | `$HOME` | `$HOME` oder `$env:USERPROFILE` |
| SSH-Keys | `~/.ssh/` | `$HOME\.ssh` |

## Troubleshooting

### Problem 1: ".cmd-Dateien starten WSL nicht"

**Diagnose:**
```powershell
where wsl
```

**Lösung:**
- WSL installieren: `wsl --install`
- Oder Git Bash: https://git-scm.com/download/win

### Problem 2: "SSH oder TFTP nicht gefunden"

**WSL:**
```bash
wsl sudo apt install openssh-client tftp-hpa
```

**Windows nativ:**
```powershell
# SSH
winget install OpenSSH.Client

# TFTP: Systemsteuerung > Windows-Features > TFTP-Client
```

### Problem 3: "PowerShell-Skripte laufen nicht"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Testen der Portierung

```bash
# In bash/WSL
./flash_efr32.sh --help

# In PowerShell
.\flash_efr32.ps1 -Help

# In CMD (mit .cmd Wrapper)
flash_efr32.cmd --help

# Über Makefile
Makefile.bat help
.\Makefile.ps1 -Command help
```

## Zukünftige Verbesserungen

- [ ] Grafische PowerShell GUI für Flash-Interface
- [ ] Native .NET-basierte TFTP-Implementierung
- [ ] Erweiterte Fehlerbehandlung in PowerShell-Versionen
- [ ] Docker-Container für vollständige Windows-Kompatibilität
- [ ] Integrierte Terminal-Funktion in Windows Terminal profile

## Zusammenfassung

Die Windows-Portierung bietet:

1. **Batch-Wrapper** (`.cmd`) — Automatische WSL/Git Bash-Erkennung ✅
2. **PowerShell-Skripte** (`.ps1`) — Experimentelle Windows-native Versionen ⚠️
3. **Dokumentation** — Ausführliche Anleitung für Windows-Nutzer 📚
4. **Quick-Start-Tools** — `Makefile.bat` und `Makefile.ps1` 🚀

**Best Practice:**
→ WSL installieren und native bash-Skripte nutzen!

---

**Fürfragen oder Bugs:** Siehe `WINDOWS_PORTING.md`

