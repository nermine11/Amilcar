#!/bin/bash

#overclocking
grep -q '^arm_freq=2200' /boot/firmware/config.txt || echo 'arm_freq=2200        # CPU frequency (MHz)' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^core_freq=250' /boot/firmware/config.txt || echo 'core_freq=250        # GPU core frequency – DO NOT go higher' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^over_voltage=6' /boot/firmware/config.txt || echo 'over_voltage=6       # Increases voltage to support higher clock' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -q '^gpu_freq=250' /boot/firmware/config.txt || echo 'gpu_freq=250         # GPU clock (safe)' | sudo tee -a /boot/firmware/config.txt > /dev/null

#stop the timesync service
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd
## Stop the triggerhappy service
sudo systemctl stop triggerhappy 
sudo systemctl disable triggerhappy
