#!/bin/bash
set -euo pipefail

################################################################################################
# File: install.sh
# Author: Andreas
# Date: 20260827
# Purpose:  Start this to install the x400_INDX Software
#
# Calls the:  install_software_2.sh, copy_configs.sh, mcu_firmware_update_all.sh
#
################################################################################################
echo "This is $(basename "$0")"
echo " "


################################################################################################
# Variables
################################################################################################
#Resolve repo root (parent of this script), then cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_DIR="$(cd "$REPO_DIR/.." && pwd)"

CLONE_PULL_SCRIPT="$REPO_DIR/scripts/git_clone_pull.sh"


################################################################################################
# Check required scripts exist and are executable
################################################################################################
required_scripts=(
  "$CLONE_PULL_SCRIPT"
  "$REPO_DIR/scripts/install_software_2.sh"
  "$REPO_DIR/scripts/copy_configs.sh"
  "$REPO_DIR/scripts/mcu_firmware_update_all.sh"
)

missing=0
for f in "${required_scripts[@]}"; do
  if [[ ! -e "$f" ]]; then
    echo "❌ Missing: $f" >&2
    missing=1
  elif [[ ! -f "$f" ]]; then
    echo "❌ Not a file: $f" >&2
    missing=1
  elif [[ ! -x "$f" ]]; then
    echo "❌ Not executable: $f  (run: chmod +x \"$f\")" >&2
    missing=1
  else
    echo "✅ Found: $f"
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "❌ Required scripts missing or not executable. Aborting." >&2
  exit 1
fi




################################################################################################
# Install required software part 2
################################################################################################
echo "ℹ️  Start software installer (install_software_2.sh) ..."
"$REPO_DIR/scripts/install_software_2.sh"
echo " "


################################################################################################
# Getting Bondtech Repositories
################################################################################################

# Download Repository https://github.com/BondtechAB/INDX/macros
set +e
"$CLONE_PULL_SCRIPT" -d "$BASE_DIR/INDX" -r "https://github.com/BondtechAB/INDX.git"
rc=$?
set -e
case "$rc" in
  0|5) ;;
  *) echo "❌ clone/pull failed: $BASE_DIR/INDX (exit $rc)" >&2; exit "$rc" ;;
esac


# download Repository https://github.com/BondtechAB/indx_klipper
set +e
"$CLONE_PULL_SCRIPT" -d "$BASE_DIR/indx_klipper" -r "https://github.com/BondtechAB/indx_klipper.git"
rc=$?
set -e
case "$rc" in
  0|5) ;;
  *) echo "❌ clone/pull failed: $BASE_DIR/indx_klipper (exit $rc)" >&2; exit "$rc" ;;
esac

# call indx_klipper/install.sh
if [[ -x "$BASE_DIR/indx_klipper/install.sh" ]]; then
  echo "ℹ️  Running indx_klipper/install.sh ..."
  "$BASE_DIR/INDX/install.sh"
else
  echo "❌ No $BASE_DIR/indx_klipper/install.sh — skip"
fi


################################################################################################
# Copy config files
################################################################################################
echo "ℹ️  Start configuration copy script (copy_configs.sh) ..."
"$REPO_DIR/scripts/copy_configs.sh" -i  || echo "❌  Faild: Starting copy_configs.sh"
echo " "


################################################################################################
# Update MCU bootloader Katapult
################################################################################################
# - not implemented yet -


################################################################################################
# Update MCU firmwares
################################################################################################
echo "ℹ️  The following script only works if Katapult is already installed on the SKIPR MCU and the INDX SMartToolhead is in bootloader mode."
read -p "❓ Install/Update Klipper firmware on the MCUs? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
  "$REPO_DIR/scripts/mcu_firmware_update_all.sh"  || echo "❌  Faild: Starting mcu_update_all.sh"
else
  echo "... no MCU firmwar update"
fi
echo " "


################################################################################################
# End
################################################################################################
echo "✅ Installation complete."
read -p "❓ Restart required. Restart now? [Y/n]: " answer
answer=${answer:-Y}     # default to "Y" if empty
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "See you later."
fi

exit 0