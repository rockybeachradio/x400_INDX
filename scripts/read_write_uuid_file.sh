#!/bin/bash
set -euo pipefail

################################################################################################
# File: read_write_uuid_file.sh
# Author: Andreas
# Date: 20250925
# Purpose:  Read the UUIDs from teh canuid.cfg
#           Ask if io? Change them.
#           Writes UUIDs to the canuid.cfg
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
# Variable declaration
################################################################################################
CONFIG_FILE="$HOME/printer_data/config/canuid.cfg"
INDX_CONFIG_FILE="$HOME/printer_data/config/indx_settings.cfg"


################################################################################################
# Checks
################################################################################################
# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found!"
  exit 1
fi

if [ ! -f "$INDX_CONFIG_FILE" ]; then
  echo "Error: $INDX_CONFIG_FILE nicht gefunden – INDX-Serial wird übersprungen."
  exit 1
fi


################################################################################################
# Read uuids
################################################################################################
# Extract canbus_uuid and serial values
mcu_canbus_uuid=$(grep -A1 "\[mcu\]" "$CONFIG_FILE" | grep "canbus_uuid" | cut -d':' -f2- | tr -d ' ')
mcu_rpi_serial=$(grep -A1 "\[mcu rpi\]" "$CONFIG_FILE" | grep "serial" | cut -d':' -f2- | tr -d ' ')

# Check if values were extracted successfully
if [ -z "$mcu_canbus_uuid" ]; then
  echo "Error: Failed to extract mcu_canbus_uuid one or more values from $CONFIG_FILE"
  exit 1
elif [ -z "$mcu_rpi_serial" ]; then
  echo "Error: Failed to extract mcu_rpi_serial one or more values from $CONFIG_FILE"
  exit 1
fi



################################################################################################
# Show current UUIDs and ask vor new one
################################################################################################
read -p "Is the mcu_canbus_uuid $mcu_canbus_uuid correct? If yes hit enter, if not, enter the new one: " answer
answer=${answer:-Y}
# If user pressed Enter (empty input), confirm the value
if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy](es)?$ ]]; then   # If answer: Y, y or yes
  echo "okay. keeping uuid."
else
  # Trim whitespace from the new value and update mcu_canbus_uuid
  mcu_canbus_uuid=$(echo "$answer" | tr -d '[:space:]')
  read -p "New value for mcu_canbus_uuid = $mcu_canbus_uuid Is the value correct [y/N]?" answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Write the new value back to the file
    sed -i "/\[mcu\]/,/^\[/ s/canbus_uuid:.*/canbus_uuid:$mcu_canbus_uuid/" "$CONFIG_FILE"   || echo "❌  Writing failed"
  
     # Check if sed command was successful
    if [ $? -eq 0 ]; then
      echo -e "\nSuccessfully updated $CONFIG_FILE"
    else
      echo -e "\nError: Failed to update $CONFIG_FILE"
    fi
  fi
fi


read -p "Is the mcu_rpi_serial $mcu_rpi_serial correct? If yes hit enter, if not, enter the new one: " answer
answer=${answer:-Y}
# If user pressed Enter (empty input), confirm the value
if [ -z "$answer" ] || [[ "$answer" =~ ^[Yy](es)?$ ]]; then   # If answer: Y, y or yes
  echo "okay. keeping uuid."
else
  # Trim whitespace from the new value and update mcu_canbus_uuid
  mcu_rpi_serial=$(echo "$answer" | tr -d '[:space:]')
  read -p "New value for mcu_rpi_serial = $mcu_rpi_serial Is the value correct [y/N]?" answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Write the new value back to the file
    sed -i "/\[mcu rpi\]/,/^\[/ s/serial:.*/serial:$mcu_rpi_serial/" "$CONFIG_FILE"   || echo "❌  Writing failed"
  
     # Check if sed command was successful
    if [ $? -eq 0 ]; then
      echo -e "\nSuccessfully updated $CONFIG_FILE"
    else
      echo -e "\nError: Failed to update $CONFIG_FILE"
    fi
  fi
fi



################################################################################################
# INDX Smart Head – Serial oder CAN-UUID
################################################################################################

if [ ! -f "$INDX_CONFIG_FILE" ]; then
  echo "Hinweis: $INDX_CONFIG_FILE nicht gefunden – INDX-Serial wird übersprungen."
else
  # Aktuellen Eintrag lesen (serial: oder canbus_uuid:)
  indx_serial=$(awk '
    $0 ~ /^\[mcu indxmcu\]/ {insec=1; next}
    insec && $0 ~ /^\[/ {insec=0}
    insec && $0 ~ /^[[:space:]]*serial:/ {
      sub(/^[[:space:]]*serial:[[:space:]]*/,""); print; exit
    }
  ' "$INDX_CONFIG_FILE")

  indx_can_uuid=$(awk '
    $0 ~ /^\[mcu indxmcu\]/ {insec=1; next}
    insec && $0 ~ /^\[/ {insec=0}
    insec && $0 ~ /^[[:space:]]*canbus_uuid:/ {
      sub(/^[[:space:]]*canbus_uuid:[[:space:]]*/,""); print; exit
    }
  ' "$INDX_CONFIG_FILE")

  # Automatisch erkennen
  detected_usb=$(ls /dev/serial/by-id/usb-Bondtech_INDX_* 2>/dev/null | head -n1 || true)

  echo ""
  echo "=== INDX Board ==="
  echo "Aktuell serial:        ${indx_serial:-<leer>}"
  echo "Aktuell canbus_uuid:   ${indx_can_uuid:-<leer>}"
  echo "Erkannt (USB by-id):   ${detected_usb:-nichts gefunden}"

  suggested="${detected_usb:-$indx_serial}"
  read -p "INDX-Pfad übernehmen/ändern? Enter = '${suggested}' behalten, sonst neuen Wert: " answer

  if [ -z "$answer" ]; then
    new_indx="$suggested"
    echo "okay. behalte: $new_indx"
  else
    new_indx=$(echo "$answer" | tr -d '[:space:]')
    read -p "Neuen Wert '$new_indx' schreiben? [y/N] " confirm
    confirm=${confirm:-N}
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      new_indx=""
    fi
  fi

  if [ -n "$new_indx" ]; then
    if [[ "$new_indx" == canbus_uuid:* ]] || [[ "$new_indx" =~ ^[0-9a-f]{12}$ ]]; then
      # CAN-UUID
      uuid="${new_indx#canbus_uuid:}"
      # serial-Zeile durch canbus_uuid ersetzen oder setzen
      if grep -q '^\[mcu indxmcu\]' "$INDX_CONFIG_FILE"; then
        if grep -A20 '^\[mcu indxmcu\]' "$INDX_CONFIG_FILE" | grep -q '^[[:space:]]*canbus_uuid:'; then
          sed -i "/\[mcu indxmcu\]/,/^\[/ s|^[[:space:]]*canbus_uuid:.*|canbus_uuid: ${uuid}|" "$INDX_CONFIG_FILE"
        else
          sed -i "/\[mcu indxmcu\]/a canbus_uuid: ${uuid}" "$INDX_CONFIG_FILE"
        fi
        sed -i "/\[mcu indxmcu\]/,/^\[/ s|^[[:space:]]*serial:.*|# serial: (durch canbus_uuid ersetzt)|" "$INDX_CONFIG_FILE"
        echo "geschrieben: canbus_uuid: $uuid"
      fi
    else
      # USB-Serial-Pfad
      if grep -q '^\[mcu indxmcu\]' "$INDX_CONFIG_FILE"; then
        if grep -A20 '^\[mcu indxmcu\]' "$INDX_CONFIG_FILE" | grep -q '^[[:space:]]*serial:'; then
          sed -i "/\[mcu indxmcu\]/,/^\[/ s|^[[:space:]]*serial:.*|serial: ${new_indx}|" "$INDX_CONFIG_FILE"
        else
          sed -i "/\[mcu indxmcu\]/a serial: ${new_indx}" "$INDX_CONFIG_FILE"
        fi
        echo "geschrieben: serial: $new_indx"
      else
        echo "Fehler: [mcu indxmcu] fehlt in $INDX_CONFIG_FILE"
      fi
    fi
  fi
fi

################################################################################################
exit 0