#!/usr/bin/env bash
# --------------------------------------------------------------------
# Universal flasher for any WaterBee build (release or debug)
# --------------------------------------------------------------------
set -euo pipefail

##############################################################################
# USER‑TUNABLE DEFAULTS
##############################################################################
DEFAULT_PORT=${PORT:-/dev/ttyUSB0}     # override:  PORT=/dev/ttyACMx ./flash_waterbee.sh
BAUD=${BAUD:-460800}
TARGET=esp32c6
##############################################################################

show_help() {
  cat <<EOF
Usage:
  ./flash_waterbee.sh [FOLDER] [PORT]

  FOLDER  Folder that contains the firmware artefacts (merged .bin + flash_args).
          • If omitted  =>  firmware/release/<latest‑version> will be used
          • If "debug"  =>  latest build inside firmware/debug/ is used
          • If a full path is supplied, that exact folder is used.

  PORT    Optional serial port. Can also be set via the PORT environment
          variable (defaults to ${DEFAULT_PORT}).

Examples
  # flash latest *release*
  ./flash_waterbee.sh

  # flash latest *debug*
  ./flash_waterbee.sh debug

  # flash an explicit folder on a specific port
  ./flash_waterbee.sh firmware/debug/waterBee_debug_1.0.47 /dev/tty.usbserial‑0001
EOF
  exit 0
}

[[ ${1:-} == "-h" || ${1:-} == "--help" ]] && show_help

##############################################################################
# Locate folder
##############################################################################
find_latest() {
  local base="$1"
  [[ -d "$base" ]] || return 1
  ls -1 "$base" | sort -V | tail -n1
}

if [[ $# -eq 0 ]]; then
  # default: newest release
  FOLDER="firmware/release/$(find_latest firmware/release)"
elif [[ $1 == "debug" ]]; then
  FOLDER="firmware/debug/$(find_latest firmware/debug)"
else
  FOLDER="$1"
fi

PORT="${2:-$DEFAULT_PORT}"

[[ -d "$FOLDER" ]] || { echo "ERROR: Folder '$FOLDER' not found" >&2 ; exit 2; }

BIN=$(ls "$FOLDER"/*.bin 2>/dev/null | head -n1)
ARGS_FILE="$FOLDER/flash_args"

[[ -f "$BIN" ]]        || { echo "ERROR: merged .bin not found in $FOLDER" >&2 ; exit 3; }
[[ -f "$ARGS_FILE" ]]  || { echo "ERROR: flash_args not found in $FOLDER" >&2 ; exit 4; }

echo "------------------------------------------------------------"
echo " WaterBee flasher"
echo "  Folder : $FOLDER"
echo "  Binary : $(basename "$BIN")"
echo "  Port   : $PORT  (baud $BAUD)"
echo "------------------------------------------------------------"

read -rp "Press <Enter> to FLASH, or Ctrl‑C to abort " _

python -m esptool --chip "$TARGET" -b "$BAUD" -p "$PORT" \
      --before default_reset --after hard_reset \
      write_flash "@$ARGS_FILE"

echo ""
echo "Flash OK!  You can now open a serial monitor:"
echo "    python -m esptool --chip $TARGET -p $PORT monitor"
