# 🧰 source_rootfs – Build Environment for Lidl Silvercrest Gateway (RTL8196E)

This directory provides everything you need to **build and deploy** a custom root filesystem (`newroot.bin`) and a writable user overlay (`userdata.tar`) for the Lidl Silvercrest Zigbee gateway based on a Realtek RTL8196E SoC.

It includes:

- ✅ A static cross-compiled **BusyBox** base system
- ✅ A lightweight static **Dropbear SSH server**
- ✅ A custom **Serial-to-TCP gateway** for UART bridging
- ✅ The official **Realtek RSDK 4.4.7** MIPS toolchain
- ✅ A staging layout that mimics the gateway's `/` and `/userdata` partitions

> 🧪 This environment can also be used to **cross-compile additional binaries** or utilities for the RTL8196E (MIPS-Lexra), making it a general-purpose embedded development framework.

---

## 📦 Getting Started

1. Download the archive [`source_rootfs.tar.gz`](https://github.com/jnilo1/hacking-lidl-silvercrest-gateway/blob/main/2-Softwares/23-Create%20the%20Root%20Filesystem/source_rootfs.tar.gz)
2. Extract it in your working directory:

```sh
tar -xvzf source_rootfs.tar.gz
cd source_rootfs
```

---

## 📁 Directory Structure Overview

```
source_rootfs/
├── build_busybox         # Build static BusyBox
├── build_dropbear        # Build static Dropbear SSH
├── build_rootfs          # Generate squashfs + newroot.bin
├── build_serialgateway   # Build UART-to-TCP bridge
├── build_userdata        # Archive ./userdata into userdata.tar
├── busybox.config        # BusyBox config file
├── rootfs/               # Rootfs staging area
│   ├── squashfs-root/    # Populated squashfs tree
│   └── rootfs_tool.py    # Packs final image
├── rsdk-4.4.7.../        # Realtek MIPS toolchain
├── serialgateway/        # Source code + Makefile
├── setup.sh              # Ubuntu dependency installer
├── userdata/             # Overlay staging for /userdata
└── README.md             # This document
```

---

## ⚙️ Build Procedure

Run the following commands in order:

```sh
./setup.sh              # Install required packages (Ubuntu)
./build_busybox         # Build BusyBox statically
./build_dropbear        # Build Dropbear statically
./build_serialgateway   # Build and install serialgateway
./build_userdata        # Package userdata.tar
```

This will generate:

- `rootfs/newroot.bin`: Flashable rootfs image (`mtd2`)
- `userdata.tar`: Overlay with configs, SSH keys (`mtd4`)

---

## 🚀 Flashing Instructions

### 1. Connect the Gateway

- **Serial** (38400 8N1, via `minicom` (linux), `teraterm` (windows), etc.)
- **Ethernet** to your LAN

### 2. Enter Bootloader Mode

```sh
reboot
```

Reboot while pressing `ESC`. You should see:

```
<RealTek>
```

---

### 3. Flash the Root Filesystem

From the host:

```sh
./build_rootfs
```

This uses TFTP to send `newroot.bin`.  
When prompted, copy/paste the suggested `FLW` command in the serial console to flash `mtd2`.

---

### 4. Deploy Writable Overlay

Once rebooted:

- Copy `userdata.tar` to the device via `scp` or `ssh`
- Unpack into `/userdata` to restore configuration

---

## 👷 Adding Your Own Binaries

To include custom tools:

1. Create a `build_<yourtool>` script similar to the others
2. Cross-compile using `rsdk-4.4.7...`
3. Place binaries in:
   - `rootfs/squashfs-root/usr/bin/` or
   - `rootfs/squashfs-root/usr/sbin/`
4. Rerun:

```sh
./build_rootfs
```

---

## 🧠 Technical Notes

- Root filesystem (`mtd2`) is mounted **read-only**
- `/userdata` (`mtd4`) is writable (JFFS2 or tmpfs)
- All binaries are **statically linked** to ensure minimal dependencies
