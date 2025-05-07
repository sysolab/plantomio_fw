waterBee ‑ Field‑Flasher – README
=================================

What’s inside?
--------------
firmware/
├─ flash_waterbee.sh        ← ONE script to flash any build
├─ README_FLASH.txt         ← this file
├─ release/
│   └─ waterBee_release_<VER>/
│       ├─ waterBee_<VER>_release_merged.bin
│       └─ flash_args
└─ debug/
    └─ waterBee_debug_<VER>/
        ├─ waterBee_<VER>_debug_merged.bin
        └─ flash_args

Prerequisites
-------------
1. **Python 3.8+** – already on macOS / most Linux.  
   Windows: install from https://python.org and *tick* “Add to PATH”.

2. A USB‑C / USB‑TTL cable plugged into the board.  
   - macOS/Linux: the port usually appears as */dev/ttyUSBx* or */dev/tty.usbmodemXXXX*  
   - Windows: *COMx*

3. (Optional) `pip install esptool`  
   *If `flash_waterbee.sh` doesn’t find esptool it will auto‑download a
   portable copy into a temp dir.*

Flashing – Quick start
----------------------
```bash
cd firmware      # <- “firmware” folder you received

# FLASH THE LATEST **release** BUILD -----------------------
./flash_waterbee.sh                       # uses the newest release + auto‐port

# FLASH A SPECIFIC FILE -----------------------------------
./flash_waterbee.sh release/waterBee_release_1.0.60 \
                    /dev/ttyUSB0          # (or COM3 on Windows)

# FLASH THE DEBUG BUILD -----------------------------------
./flash_waterbee.sh debug/waterBee_debug_1.0.60

# If the script can’t guess the port:
./flash_waterbee.sh release/waterBee_release_1.0.60 COM5
