Welcome, to my software pack for the Eryone Thinker x400 with Bondtech INDX

# Information about this project
This is an Firmware for the Eryone Thinker x400 with Bondtech INDX \
    https://github.com/rockybeachradio/x400_INDX \
 \
 This uses a RaspberryPi 5 instead using the MKS SKIPR SoC. \
 \
It is based on https://github.com/rockybeachradio/x400-software-pack \


# Known bugs
- [ ] at24c_eeprom: Error during Klipper start.


# Backlog:

## ToDo
- [ ] Remove "duplicate_pin_override" in chamber_temp_mgmt.cfg --> Software solution, or another temperature sensor

## Research on the following tools, if they should be part of x400-software-pack:
- [ ] SimplyPrint: https://simplyprint.io
- [ ] PrettyGCode: https://github.com/Kragrathea/pgcode


## Software modifications
- [ ] printer.cfg - modified
- [ ] Create INDX.cfg: https://github.com/BondtechAB/INDX#firmware-configuration
- [ ] installation script
    - [ ] Incorporate: https://github.com/BondtechAB/INDX#firmware-configuration
    - [ ] Incorporate: https://github.com/BondtechAB/INDX/tree/main/macros
    - [ ] Incorporate: https://github.com/BondtechAB/indx_klipper
- [ ] update script
    - [ ] Incorporate: https://github.com/BondtechAB/INDX#firmware-configuration
    - [ ] Incorporate: https://github.com/BondtechAB/INDX/tree/main/macros
    - [ ] Incorporate: https://github.com/BondtechAB/indx_klipper
- [ ] CFG fiels cleand

## Hardware modifications
- [ ] Bondtech INDX
    - [ ] Bondtech INDX Toolhead
    - [ ] Bondtech electronic board
    - [ ] Bondtech INDX Eddy Current Scanner
    - [ ] Bondtech INDX Tool Dock
    - [ ] x-axis endstop switch
    - [ ] x-carriage
        - [x] CAD model
    - [ ] 1515 aluminum bar
    - [ ] aluminium bar mount
        - [x] CAD model
- [ ] Cable & Tube routing
    - [ ] Cable routing
    - [ ] Filament tube routing
- [ ] Enclosure
- [ ] Material Storage
    - [ ] Enclosure
    - [ ] Filament storage
    - [ ] Roshal Dehumidifier
- [ ] Automatic feeder: Drom Spool to passive Tool
- [ ] Nozzle camera: Check Nozzle alignment

- [ ] Second temperature sensor for chamber exhaust fan / chamber heater
- [ ] Poop bin (my be combined with Nozzle Cleaning Station)
- [ ] Nozzle Cleaning Station (left side)

- [ ] Chamber fan (exhaust) v3: lid which closes and opens (optimized mounting)) --> Integrated in Chamber exhaust system
- [ ] Chamber Filtration System (exhaust fan) : lid, bigger coal filter and HEPA filter, pre filter
    - [ ] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Electronic bay fan filter
    - [ ] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Chamber filtration unit: Coal Filter and HEPA filter (recirculation air)
    - [ ] Constructed
    - [ ] Adapted to actual printer size
    - [ ] Printed and Tested
- [ ] Auxilliary part cooling fan (G-Code M106, M107)

- [ ] RBG Status LED for printer status indication (Neopicel pin:PC5)
- [ ] Better Camera

## Added Features
- Backup script function
    - [x] Backup as zip to local backup folder
    - [ ] Upload zip to SMB
    - [x] Backup to GitHub
    - [ ] GitHub: Initial setup local fodler (/printer_backup/files/) in install_software.sh
        --> git_initiate.sh: Test "Git commands" section. 
- [ ] Temeprature monitoring (what to do when to hot)
- [ ] Endstoop calibration [endstop_phase]
- Update functionality with moonraker. Add in Moonraker.conf [update_manager]:
    - [ ] G-Code Shell Command
    - [ ] Input Shaper

## Added Software
- [ ] Mobileraker - Mobile App support \
        https://github.com/Clon1998/mobileraker
        https://github.com/Clon1998/mobileraker_companion
    - [x] installation
    - [ ] setup
    - [ ] in backup included (backup script & klipper-backup)
- [ ] Obico support for local AI server \
    https://www.obico.io/docs/user-guides/klipper-setup/
    https://www.obico.io/docs/server-guides/
    - [x] installation
    - [ ] setup
    - [ ] in backup included (backup script & klipper-backup)


# How Tos
## Before installing
- Install RaspberryPi (Connect all USB and HDMI cables to the RPI)
- Install 2 additional Thermostate sensors (Second chamber temp sensor, Environment sensor)
- Setup the RapsberryPi with the RaspberryPi os (Trixy) inclunding X11 Desktop.

#### optional:
- Add RGB light and connect it to NeoPixel port.


## How to Install?
> [!NOTE]
> Read all the documentation: Eryone, Bondtech, Klipper, Mainsail, Moonraker, etc.
> [!CAUTION]
> Be aware that every modification on the device and software may void the garanty and may damage the device.


### First boot
1) Start the RPI and printer. \
   The IP-Adress of the printer will be shown in its display.

2) Connect to the printer as <YOUR_USER> via SSH.
    ```bash
    ssh <YOUR_USER>@<PRINTER_IP>
    ```

### Install the software
1) Clone the repo to the local machine
    ```bash
    cd ~/
    git clone https://github.com/rockybeachradio/x400-INDX
    ```

2) Install software part 1
    ```bash
    ~/x400-INDX/scripts/install.sh
    ```
    If asked:
    - iperf3 launch at start: no


2) Install components via KIAUH
If asked select: 3) Yes, use v6 and remember choice

In KIAUH: \
    1) Install \
        1.1) Klipper \
        1.2) Moonraker \
        1.3) Mainsail \
        1.5) Mainsail-Config \
        1.7) KlipperScreen
            --> X11 (nicht wayland) \
            --> NetworkManager: yes  # After installing, the system is going to reboot.  \
        1.8) Crowsnest \
    4) Advances \
        4.5)Input Shaper Dependencies \
            --> If asked: Install needed software: YES \
    E) Extension \
        E.1) G-Code Shell Command \
        E.3) Mobileraker   (optional) \
        E.4) Klipper-Backup  (optional: Backup on boot, Cron, Backup on file changes) \
        E.6) Obico for Klipper  (optional) \
Use the default settings during installatios \
If asked, install al example files / demo configs.

KIAUH can be launched any time with the command:
    ```bash
    ~/kiauh/kiauh.sh
    ```

4) Klipper Backup (if installed)
Open the ~/KlipperBackup/.env file and add your GitHub credentials.
    ```bash
    cd ~/klipper-backup/
    nano .env
    ```

5) Install software part 2
    ```bash
    ~/x400-sINDX/scripts/install_part2.sh
    ```

6) Reboot the system
    ```bash
    sudo reboot
    ```

### Installing Klipper firmware on the MCUs
1) Katpult: Install/update Katapult on your boards (MCU, toolhead)

2) Klipper Firmware: Install/update Firmware on your boards (MCU, toolehad)
mcu-update_all.sh can be used.

3) Install Linux MCU rpi
mcu-update_all.sh can be used.

3) Reboot
    ```bash
    sudo reboot
    ```

### Settings
1) Settings in Mainsaol
1.1) Camera - already set up
1.2) Display CANCEL_PRINT in Interface Settings - UI-Settings
1.3) Create Macro groups in Interface Settings - Macros
1.3.1) Printing: Load filament; Unload filament; print continue
1.3.2) System: Shutdown


### Useful links
1) Mainsail: http://<PRINTER_IP>:80
2) Moonraker: http://<PRINTER_IP>:7125

### Check setup 
1) Check all settings and printerbehaviour as descirped in Klipper, Mainsail, Moonraer documentation to avoid issues and damages.


## How to update x400-software-pack
```bash
~/x400-INDX/scripts/update.sh
```

## How to flash the MCUs
```bash
~/x400-INDX/scripts/mcu-update_all.sh
```

## How to reset x400-software-pack
x400-software-pack can be reinstalled.
```bash
~/x400-INDX/scripts/install.sh
~/x400-INDX/scripts/install_part2.sh
```

## How deleat local x400-software-pack repo copy
As it is a copy of a repo, just delet the local reopo folder.
```bash
rm -r ~/x400-INDX"
```
Note: This will not uninstall software nor deleat any (config) files, folders, etc. which were created during installation.
This need to be done manually.



# Useful stuff for terminal (german keyboard layout)
```bash
~   alt + n
[   alt + 5
]   alt + 6
|   alt + 7
{   alt + 8
}   alt + 9
/   shift + 7
\   alt + shift + 7

close programs    ctrl + c
```


# Sources
#### Eryone Thinker x400 printer:
- https://eryone.com/
- https://eryone3d.com/products/thinker-x400/
- https://eryonewiki.com/
- https://www.facebook.com/groups/eryoneofficial/
- https://www.facebook.com/groups/thinkerx400/

#### Eryone Repositories:
- GitHub: https://github.com/Eryone/
- GitHub: https://github.com/Eryoneoffical/
- Gitee: https://gitee.com/everyone3d/
- GitCode: https://gitcode.com/xpp012/KlipperScreen/

#### Makerbase MKS:
- https://makerbase.com.cn/en/
- https://github.com/makerbase-mks/

### Bondtech INDX:
- https://github.com/BondtechAB/INDX
- https://github.com/BondtechAB/indx_klipper
- https://github.com/BondtechAB/indx-bootloader

#### Armbian for MKS boards (The Linux which is used):
- GitHub: https://github.com/redrathnure/armbian-mkspi

#### Informations:
- Eryone toolhead board: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs
- Eryone pressure sensor:
    - code: https://gitee.com/everyone3d/stm32_pressure_sensor
    - binary: https://gitcode.com/xpp012/KlipperScreen/tree/master/docs/X400_firmware
- Eryone x400 3d printed Parts: https://github.com/Eryoneoffical/X400_printed_parts_cad_files
- Eryone farm3d:
    - https://github.com/Eryone/farm3d
    - https://gitcode.com/xpp012/KlipperScreen/tree/master/farm3d

All rellevant Eryone documents, files are part are collected from all soruces and part of this Repository.

## Repo checked for changes/updates:
https://gitcode.com/xpp012/KlipperScreen/ - last check 20251017 (a615b786)
