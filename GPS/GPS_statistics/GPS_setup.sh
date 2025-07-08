#!/bin/bash

#Update rPi and install packages
sudo apt update
sudo apt upgrade
# this isn't really necessary, maybe if you have a brand new pi
# sudo rpi-update
sudo apt install pps-tools gpsd gpsd-clients chrony

#Set up the Pi to release the console pins
#free the UART port (in our case /dev/ttyS0) for GPS communication,
sudo raspi-config nonint do_serial_cons 1

#Enable PPS
sudo bash -c "echo '# the next 3 lines are for GPS PPS signals' >> /boot/firmware/config.txt"
# Enable GPIO-based PPS (Pulse-Per-Second) on pin 4 for GPS timing
sudo bash -c "echo 'dtoverlay=pps-gpio,gpiopin=4' >> /boot/firmware/config.txt"
# Enable the UART serial interface hardware to communicate with the GPS module
sudo bash -c "echo 'enable_uart=1' >> /boot/firmware/config.txt"
# Set default serial communication speed to 9600 baud to matches our GPS module
sudo bash -c "echo 'init_uart_baud=9600' >> /boot/firmware/config.txt"

#In /etc/modules, add ‘pps-gpio’ to a new line.
sudo bash -c "echo 'pps-gpio' >> /etc/modules"

#Edit /etc/default/gpsd:
#Installing a GPS Daemon (gpsd)
#serial might be /dev/ttyAMA0
#comment these two lines
sudo sed -i 's|^DEVICES=""|#DEVICES=""|; s|^GPSD_OPTIONS=""|#GPSD_OPTIONS=""|' /etc/default/gpsd
sudo bash -c "echo 'DEVICES=\"/dev/ttyS0 /dev/pps0\"' >> /etc/default/gpsd"
# -n means start without a client connection (i.e. at boot)
sudo bash -c "echo 'GPSD_OPTIONS=\"-n\"' >> /etc/default/gpsd"
# also start in general
sudo bash -c "echo 'START_DAEMON=\"true\"' >> /etc/default/gpsd"
# Automatically hot add/remove USB GPS devices via gpsdctl
sudo bash -c "echo 'USBAUTO=\"false\"' >> /etc/default/gpsd"

#configure chrony to use both NMEA and PPS signals
# SHM refclock is shared memory driver, it is populated by GPSd and read by chrony
# it is SHM 0
# refid is what we want to call this source = NMEA
# offset = 0.000 means we do not yet know the delay
# precision is how precise this is. not 1e-3 = 1 millisecond, so not very precision
# poll 0 means poll every 2^0 seconds = 1 second poll interval
# filter 3 means take the average/median (forget which) of the 3 most recent readings. NMEA can be jumpy so we're averaging here
sudo bash -c "echo 'refclock SHM 0 refid NMEA offset 0.000 precision 1e-3 poll 0 filter 3 prefer'>>/etc/chrony/chrony.conf"

# PPS refclock is PPS specific, with /dev/pps0 being the source
# refid PPS means call it the PPS source
# lock NMEA means this PPS source will also lock to the NMEA source for time of day info
# offset = 0.0 means no offset... this should probably always remain 0
# poll 3 = poll every 2^3=8 seconds. polling more frequently isn't necessarily better
# trust means we trust this time. the NMEA will be kicked out as false ticker eventually, so we need to trust the combo
sudo bash -c "echo 'refclock PPS /dev/pps0 refid PPS lock NMEA offset 0.0 poll 3 trust prefer'>>/etc/chrony/chrony.conf"

# also enable logging by uncommenting the logging line
sudo bash -c "echo 'log tracking measurements statistics'>>/etc/chrony/chrony.conf"

#ensure start on boot
#sudo systemctl stop gpsd.socket
#sudo systemctl disable gpsd.socket
sudo systemctl enable gpsd.socket
sudo systemctl start gpsd.socket
#sudo systemctl enable gpsd
#sudo systemctl unmask gpsd	
#sudo service gpsd restart

#Restart chrony
sudo systemctl restart chrony
sudo reboot