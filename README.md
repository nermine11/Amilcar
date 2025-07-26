# Amilcar

This setup is designed to run on a Raspberry Pi, synchronizing its internal clock with GPS time and recording audio- files with timestamps of each second using a hydrophone.
It is part of **Falco/OpenSwarm** collabration to count the number of motor boats in marine protected areas

NOTE: this repository needs to be cloned or unzipped in `/home/pi/Amilcar`

## Hardware requirements
-  Raspberry Pi 5 for better time precision
-  Adafuit ultimate GPS HAT
-  GPS antenna for better time accuracy
-  Hydrophone
-  ADC/DAC pro

We are using GPS to set the internal time of the rPi, and using Raspberry Pi 5 RTC as fallback in case we lose GPS fix.

The RTC is disciplined by GPS every second.

## Configuring AMILCAR



### Step 1: Flash Operating System to the micro-SD card

Depending on your computer operating system, the installation procedure can change. 
Please follow the instruction on the Raspbian website: https://www.raspberrypi.com/software/

From the link above download and install the Raspberry Pi Imager.

In the Raspberry Pi Imager select:
- Device           - Raspberry Pi 5,  
- Operating System - Raspberry Pi OS (64-BIT)
- Storage          - micro-SD card

After flashing, insert the micro-SD into the Raspberry Pi. 
Power ON the Raspberry and connect it to a screen with an HDMI cable, and connect a mouse and a keyboard.

On the first boot of the OS you need to fill in the location and language info, username and password.

For the username type: `pi`
For the password type: `raspberry`

### Step 2: Enable SSH using Ethernet cable

- Check the name of ethernet interface using:
```
nmcli device status
```
then run the following command to be able to SSH from your computer to the rPi using an ethernet cable
```
sudo nmcli con mod "name of ethernet interface" ipv4.addresses 192.168.50.2/24 ipv4.gateway 192.168.50.1 ipv4.dns 8.8.8.8 ipv4.method manual

```



### Step 2: Download and install Amilcar 
From your Raspberry Pi download the latest Release or clone the repository of Amilcar here: [https://github.com/nermine11/Amilcar] This repository needs to be cloned or unzipped in `/home/pi/Amilcar`

Unzip the content of the release in the /home/pi/Amilcar folder and run the following commands:
**make the file executable**
```
sudo chmod +x install_amilcar.sh
```
**Run**
```
source install_amilcar.sh
```
### Step 3: Set the internal time of the rPi as GPS time, 
***Run GPS_setup.sh***
  ```
 sudo chmod +x GPS/GPS_setup.sh
 ./GPS/GPS_setup.sh
 ```
Comment manually to not use Interent time servers the content of 
- #debian vendor zone
- #use time sources from dhcp
- #use ntp sources 
found in /etc/chrony/chrony.conf

- check /GPS to see how to choose the offsett 
 
### Step 4: Setup the RTC 
***Run RTC_setup.sh***
```
 sudo chmod +x RTC/RTC_setup.sh
./RTC/RTC_setup.sh
```
### Step 5: Discipline the RTC using GPS and use RTC as fallback 

**Make  the file RTC_GPS_sync.sh executable**
```
sudo chmod +x ./GPS/RTC_GPS_sync.sh

```
**Create a systemd Service File**
```
sudo nano /etc/systemd/system/rtc-gps-sync.service
```

**Paste the following content:**
```
[Unit]
Description=RTC fallback
After=gpsd.service
Wants=gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/GPS/RTC_GPS_sync.sh
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
sudo systemctl start RTC_GPS_sync.service
```

**And automatically get it to start on boot:**
```
sudo systemctl enable RTC_GPS_sync.service
```

**Reboot the Raspberry**
```
sudo reboot
```

### Step 6: add audio group to user
```
sudo usermod -aG audio pi
sudo reboot
```

### Step 4: configure ADC+DAC converter
***Run setup_audip.sh***
```
 sudo chmod +x audio/setup_audio.sh
./audio/setup_audio.sh
```

### Step 7: reduce latency

**Make  the file reduce_latency_on_boot.sh executable and run it**
```
sudo chmod +x ./audio/reduce_latency_on_boot.sh
./audio/reduce_latency_on_boot.sh
```

**Make  the file reduce_latency.sh executable**
```
sudo chmod +x ./audio/reduce_latency.sh
```

**Create a systemd Service File**
```
sudo nano /etc/systemd/system/reduce_latency.service
```

**Paste the following content:**
```
[Unit]
Description=reduce latency

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/home/pi/Amilcar/audio/reduce_latency.sh

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
sudo systemctl start reduce_latency.service
```

**And automatically get it to start on boot:**
```
sudo systemctl enable reduce_latency.service
```

**Reboot the Raspberry**
```
sudo reboot
```
### Step 8: Increase audio volume

check /audio for more details
```
amixer -D hw: 0 cset name='ADC Capture Volume' 96,96
sudo alsactl store
```

### Step 9: run the jack server to record audio

**Create a systemd Service File**
```
sudo nano /etc/systemd/system/jack_server.service
```

**Paste the following content:**
```
[Unit]
Description=run jack server

[Service]
Restart=always
RestartSec=1
User=pi
Group=audio
ExecStart=/usr/bin/jackd -P70 -t 2000 -d alsa -d hw:0 -r 44100 -p2048 -n3

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
sudo systemctl start jack_server.service
```

**And automatically get it to start on boot:**
```
sudo systemctl enable jack_server.service
```

**Reboot the Raspberry**
```
sudo reboot
```

### Step 10: record audio

**Create a systemd Service File**
```
sudo nano /etc/systemd/system/record_audio.service
```

**Paste the following content:**
```
[Unit]
Description=Hydrophone Audio Recorder
After=jack_server.service gpsd.service
Wants=jack_server.service gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/venv/bin/python /home/pi/Amilcar/audio/record_audio.py
WorkingDirectory=/home/pi/Amilcar
Restart=always
RestartSec=1
User=pi
Group=audio

[Install]
WantedBy=multi-user.target
```
**save and exit**

**Reload the service files to include the new service.**
```
sudo systemctl daemon-reload
```

### Step 11: add a timer for record audio

We want to start recording after 10 minutes of reboot, so that the 3 rPis could start more or less at the same time, and to give some time for GPS fix, so we will use a  .timer systemd unit file


**Create a systemd Service File**
```
sudo nano /etc/systemd/system/record_audio.timer
```

**Paste the following content:**
```
[Unit]
Description=timer for Hydrophone Audio Recorder

[Timer]
OnBootSec=10min
Unit=record_audio.service

[Install]
WantedBy=timers.target
```
**save and exit**

**Reload the service files to include the new service.**
```
sudo systemctl daemon-reload
```
**Disable record_audio.service so it don't start on boot
```
sudo systemctl disable record_audio.service

```

**Start and enable the service:**
```
sudo systemctl start record_audio.timer
```

**And automatically get it to start on boot:**
```
sudo systemctl enable record_audio.timer
```

**Reboot the Raspberry**
```
sudo reboot
```






