#!/usr/bin/env bash

################################################################################################
# File: indx_smarttoolhead_firmware_update.sh
# Author: Andreas
# Date: 20260826
# Purpose: Updates the Bondtech INDX SmartToolhead Firmware.
#
# How to call:
#   chmod +x update_indx_smarttoolhead_firmware_update.sh
#   ./update_indx_smarttoolhead_firmware_update.sh
#   
################################################################################################


################################################################################################
# Error handling
################################################################################################
set -euo pipefail                                   # Definiert Abbruchkriterien für Skript:
                                                    # set -e - Wenn ein Befehl fehlschlägt.
                                                    # set -u - Wenn eine nicht gesetzte Variable verwendet wird.
                                                    # set -o pipefail - Bei Befehlen mit Pipe (|) wir der erste Fehler im Pipeline-Verlauf erkannt.
error_exit() { echo "! ERROR: $1" >&2; exit 1; }    # Funktion error_exit: Shows an error message and EXIT the script. error_exit is called whenever an error in the script occures


################################################################################################
# Welcome
################################################################################################
echo "ℹ️  This is $(basename "$0")"






## Mainline Klipper does not include INDX support. Add it with the indx_klipper module, then build and flash:
#cd ..
#cd ..
#git clone https://github.com/BondtechAB/indx_klipper.git
#cd indx_klipper
#./install.sh /home/pi/klipper        # adjust the path to your Klipper install




################################################################################################
# Varibale declaration
################################################################################################
#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MCU_BOOTLOADER_CONFIGS_DIR="$REPO_DIR/mcu-bootloader-configurations"
MCU_FIRMWARE_CONFIGS_DIR="$REPO_DIR/mcu-firmware-configurations"


KLIPPER_DIR="${HOME}/klipper"          # Change if your Klipper/Kalico lives elsewhere
INDX_KLIPPER_DIR="../${REPO_DIR}/indx_klipper
FLASH_DEVICE="04d8:e483"
CONFIG="board_configs/bondtech_indx_usb.config"
GIT_INDX_KLIPPER="https://github.com/BondtechAB/indx_klipper.git"

IS_KALICO=false
IS_KLIPPER=false

################################################################################################
# Script exit routines
################################################################################################
echo "=== Bondtech INDX SmartToolhead Firmware Updater ==="
echo

################################################################################################
# Checks
################################################################################################
# Check if SmartToolehad is in bootloader mode
if ! lsusb | grep -q "04d8:e483"; then
    echo "ERROR: INDX bootloader not found (04d8:e483)."
    echo "1. Power off the printer / Smart Head"
    echo "2. Fit the CAN RESET jumper on the INDX MCU PCB"
    echo "3. Power on again"
    echo "4. Re-run this script"
    exit 1
fi
echo "ℹ️  Bootloader detected"


# Check if Klipper Directory exists
if [ ! -d "${KLIPPER_DIR}" ]; then
    echo "❌  Neither Kalico nor Klipper found at ${KLIPPER_DIR}"
    echo "Aborting."
    exit 1
fi
echo "ℹ️  Klipper detected"


# Check if Kalico or Klipper is used
if [ -f "${KLIPPER_DIR}/board_configs/bondtech_indx_usb.config" ]; then
    IS_KALICO=true
    echo "ℹ️  Kalico detected (native INDX support)"
elif [ -f "${KLIPPER_DIR}/klippy/__init__.py" ] || [ -f "${KLIPPER_DIR}/klippy/chelper/__init__.py" ]; then
    # Basic check that this looks like a Klipper tree
    IS_KLIPPER=true
    echo "ℹ️  Mainline Klipper detected"

    if [ ! -d "${INDX_KLIPPER_DIR}" ]; then
        echo "❌  INDX_Klipper does not exist."
        echo "Please install INDX_Klipper via install.sh script first."
        exit 1
    fi
fi



################################################################################################
# FFlashing
################################################################################################
if [ "${IS_KALICO}" = true ]; then
    echo "Firmwareupdate via Kalico"
    cd "${KLIPPER_DIR}"
    echo "Building firmware..."
    KCONFIG_CONFIG="${CONFIG}" make
    echo "Flashing..."
    KCONFIG_CONFIG="${CONFIG}" make flash FLASH_DEVICE="${FLASH_DEVICE}"

elif [ "${IS_KLIPPER}" = true ]; then
  echo "Firmwareupdate via Klipper"
  cd "${HOME}/indx_klipper"
  echo "Building firmware..."
  make
  echo "Flashing..."
  make flash FLASH_DEVICE="${FLASH_DEVICE}"
fi
echo "✅  Flash complete"

################################################################################################
# Completion Info
################################################################################################
echo
echo "Restart SmartToolhead"
echo "1. Power off the printer / Smart Head"
echo "2. REMOVE the CAN RESET jumper"
echo "3. Power on again"
echo "4. Restart Klipper / Kalico (or reboot the host)"
echo
echo "Afterwards the board should appear as:"
echo "  /dev/serial/by-id/usb-Bondtech_INDX_...-if00"


################################################################################################
# Done
################################################################################################
echo "✅  Done :-)"
exit 0



