#!/bin/bash

#overclocking
grep -q '^arm_freq=2200' /boot/firmware/config.txt || echo 'arm_freq=2200        # CPU frequency (MHz)' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^core_freq=250' /boot/firmware/config.txt || echo 'core_freq=250        # GPU core frequency – DO NOT go higher' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^over_voltage=6' /boot/firmware/config.txt || echo 'over_voltage=6       # Increases voltage to support higher clock' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^gpu_freq=250' /boot/firmware/config.txt || echo 'gpu_freq=250         # GPU clock (safe)' | sudo tee -a /boot/firmware/config.txt > /dev/null

sudo tee /etc/modprobe.d/raspi-blacklist.conf > /dev/null <<EOF
# WiFi
#blacklist brcmfmac
#blacklist brcmutil

# Bluetooth
blacklist btbcm
blacklist hci_uart
EOF

#sudo apt purge --auto-remove pi-greeter lightdm lx* gvfs*  xserver-common policykit-1 gnome* x11* openbox* xdg*  pulseaudio  triggerhappy gvfs gvfs-daemons gvfs-backends gvfs-fuse
 
sudo apt purge --auto-remove  pulseaudio 

#disable leds
sudo tee -a /boot/firmware/config.txt > /dev/null <<EOF
# Disable ACT LED (SD card activity)
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off

# Disable PWR LED (power status)
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
EOF


SERVICES=(
  systemd-timesyncd        # stop the timesync service
  triggerhappy             # Stop the triggerhappy service
  bluetooth                # Stop the bluetooth service
  ModemManager             # Handles cellular USB modems
  #wpa_supplicant          # Wi-Fi connection manager
  avahi-daemon             #For local hostname discovery
  cups                     #printing service
  cron                     # scheduled tasks not used
  anacron                  # scheduled tasks not used
  man-db.timer             #Updates man page 
  apt-daily.service        # auto checks for package updates
  apt-daily.timer          # auto checks for package updates
  apt-daily-upgrade.timer  # auto checks for package updates
  #alsa-restore
  hciuart                  #Initializes Bluetooth chip over UART
  #keyboard-setup          #configures keyboard layout setup on boot## Stop the polkitd service. Warning: this can cause unpredictable behaviour when running a desktop environment on the RPi
  #polkit                   #controlling system-wide privileges
)

for svc in "${SERVICES[@]}"; do
  systemctl stop "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
done
