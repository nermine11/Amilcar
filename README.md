# Amilcar

This setup is designed to run on a Raspberry Pi, synchronizing its internal clock with GPS time and recording audio- files with timestamps of each second using a hydrophone.
It is part of **Falco/OpenSwarm** collabration to count the number of motor boats in marine protected areas

NOTE: The this repository needs to be cloned or unzipped in `/home/pi/Amilcar`

## Hardware requirements
-  Raspberry Pi
-  Adafuit ultimate GPS HAT
-  GPS antenna for better time accuracy
-  Hydrophone
-  ADC/DAC pro
-  Adafruit DS3231 RTC

We are using GPS to set the internal time of the rPi, and using RTC as fallback in case we lose GPS fix.

The RTC is disciplined by GPS every second.

## Configuring AMILCAR

### Step 1: Flash Operating System to the micro-SD card

Depending on your computer operating system, the installation procedure can change. 
Please follow the instruction on the Raspbian website: https://www.raspberrypi.com/software/

From the link above download and install the Raspberry Pi Imager.

In the Raspberry Pi Imager select:
- Device           - Raspberry Pi 4,  
- Operating System - Raspberry Pi OS (64-BIT)
- Storage          - micro-SD card

After flashing, insert the micro-SD into the Raspberry Pi. 
Power ON the Raspberry and connect it to a screen with an HDMI cable, and connect a mouse and a keyboard.

On the first boot of the OS you need to fill in the location and language info, username and password.

For the username type: `pi`
For the password type: `raspberry`

***Open terminal in Amilcar folder***
### Step 2: Set the internal time of the rPi as GPS time, 
***Run GPS_setup.sh***
  ```
 sudo chmod +x GPS/GPS_setup.sh
 ./GPS/GPS_setup.sh
 ```
-> Comment manually
whats under use debian vendor zone
use time sources from dhcp
use ntp sources found in etc/chrony/sources.d
### Step 3: Setup the RTC 
***Run RTC_setup.sh***
```
 sudo chmod +x RTC/RTC_setup.sh
./RTC/RTC_setup.sh
```
### Step 4: Discipline the RTC using GPS and use RTC as fallback 
***Move RTC_GPS_sync.sh***
```
sudo mv RTC/RTC_GPS_sync.sh /usr/local/bin/RTC_GPS_sync.sh
```
**Make  the file RTC_GPS_sync.sh executable**
```
sudo chmod +x /usr/local/bin/RTC_GPS_sync.sh

```
**Create a systemd Service File**
```
sudo nano /etc/systemd/system/rtc-gps-sync.service
```

**Paste the following content:**
```
[Unit]
Description= RTC fallback
After=network.target gpsd.service
Wants=gpsd.service

[Service]
ExecStart=/usr/local/bin/RTC_GPS_sync.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
```
**save and exit**

**Reload the service files to include the new service.**
```
sudo systemctl daemon-reload
```
**Start and enable the service:**
```
systemctl start RTC_GPS_sync.service
```
**And automatically get it to start on boot:**
```
systemctl enable RTC_GPS_sync.service
```
