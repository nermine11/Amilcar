#!/bin/bash

## Set the CPU scaling governor to performance
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  echo performance | sudo tee $cpu/cpufreq/scaling_governor
done


## Remount /dev/shm to prevent memory allocation errors
mount -o remount,size=128M /dev/shm
## Stop the polkitd service. Warning: this can cause unpredictable behaviour when running a desktop environment on the RPi
killall polkitd
## Kill the usespace gnome virtual filesystem daemon. Warning: this can cause unpredictable behaviour when running a desktop environment on the RPi
killall gvfsd
## Stop the dbus service. Warning: this can cause unpredictable behaviour when running a desktop environment on the RPi
service dbus stop 
## Kill the userspace D-Bus daemon. Warning: this can cause unpredictable behaviour when running a desktop environment on the RPi
killall dbus-daemon 

