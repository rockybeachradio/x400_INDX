#!/bin/bash
set -euo pipefail

################################################################################################
# File: install_software_indx.sh
# Author: Andreas
# Date: 20260827
# Purpose:  Install / Update INDX software
#
# Calls the:  install_part2.sh, update.sh
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

CLONE_PULL_SCRIPT="$REPO_DIR/scripts/git_clone_pull.sh"

KLIPPER_DIR="${HOME}/klipper"


################################################################################################
# Check required scripts exist and are executable
################################################################################################
required_scripts=(
  "$CLONE_PULL_SCRIPT"
  "$REPO_DIR/scripts/install_software_indx.sh"
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
# Getting / Updating Bondtech`s indx_klipper Repository
################################################################################################
# To extend (mainline) Klipper with MultiToolhead functionality

# Download/Update Repository https://github.com/BondtechAB/indx_klipper
set +e
"$CLONE_PULL_SCRIPT" -d "${HOME}/indx_klipper" -r "https://github.com/BondtechAB/indx_klipper.git"
rc=$?
set -e
case "$rc" in
  0|5) ;;
  *) echo "❌ clone/pull failed: ${HOME}/indx_klipper (exit $rc)" >&2; exit "$rc" ;;
esac

# Install indx_klipper
if [[ -x "${HOME}/indx_klipper/install.sh" ]]; then
  echo "ℹ️  Running indx_klipper/install.sh ..."
  "${HOME}/INDX/install.sh" "${KLIPPER_DIR}"
else
  echo "❌ No ${HOME}/indx_klipper/install.sh — skip"
fi


################################################################################################
# Getting / Updating Bondtech`s INDX Repository
################################################################################################
# INDX Macos

# Download/Update Repository https://github.com/BondtechAB/INDX/
set +e
"$CLONE_PULL_SCRIPT" -d "${HOME}/INDX" -r "https://github.com/BondtechAB/INDX.git"
rc=$?
set -e
case "$rc" in
  0|5) ;;
  *) echo "❌ clone/pull failed: ${HOME}/INDX (exit $rc)" >&2; exit "$rc" ;;
esac


################################################################################################
exit 0