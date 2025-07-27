# Amilcar

This setup is designed to run on a Raspberry Pi, synchronizing its internal clock with GPS time and recording audio- files with timestamps of each second using a hydrophone.
It is part of **OpenSwarm** project to count the number of motor boats in marine protected areas,
the data will be used by IMEC to train their machine learning algorithms.

NOTE: this repository needs to be cloned or unzipped in `/home/pi/Amilcar`

## Hardware requirements
-  3 Raspberry Pi 5 for better time precision
-  3 Adafuit ultimate GPS HAT with CRC1220 small battery
-  3 GPS antennas for better time accuracy, use the same GPS antenna for better accurancy
-  3 Hydrophone
-  3 ADC/DAC pro
-  3 power banks
-  3 rPi5 cooling fans


We are using GPS to set the internal time of the rPi, and using Raspberry Pi 5 RTC as fallback in case we lose GPS fix.

The RTC is disciplined by GPS every second.
We are using JACK for real time recording with a python script check ./audio for more details on the recording


We will also have a Raspberry Pi to locate the boat every second,
check ./localization for more details on the configuration

## Some considerations:
- We use rPi 5 for its better time accuracy, rPi5 requires 5V/5A or 5v/3A while reducing USB current so we chose 5V/3A power banks
- the recording consumes lots of CPU power, the rPi gets very hot (83 degrees) and it throttles at 80 degress so better use a cooling fan!
- Sometimes we get an IO error because of the load on the rPi, if you want a system that will stay all the time in the sea, look for other options than the rPi as it 
already requires many tweaking to record in real time,
- There will always be jitter so non perfect synchronization between the recordingd of the rPis (in our case 25ms) this jitter can't be adressed by the software 
  but by hardware 



## Configuring AMILCAR


### Step 1: Flash Operating System to the micro-SD card

Depending on your computer operating system, the installation procedure can change. 
Please follow the instruction on the Raspbian website: https://www.raspberrypi.com/software/

From the link above download and install the Raspberry Pi Imager.

In the Raspberry Pi Imager select:
- Device           - Raspberry Pi 5,  
- Operating System - Raspberry Pi OS (64-BIT)
- Storage          - micro-SD card 256 GO minimum

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
better use different IP address for each rPi

### Step 3: Download Amilcar and install real time kernel
From your Raspberry Pi download the latest Release or clone the repository of Amilcar here: [https://github.com/nermine11/Amilcar] This repository needs to be cloned or unzipped in `/home/pi/Amilcar`

Unzip the content of the release in the /home/pi/Amilcar folder 
We are going to record in real time so we to be able to do that, we will install a real time kernel
instead of rPi kernel which is best-effort,
the difference is a real time kernel will give absolute priority to our recording while 
best-effort can have milliseconds of latency and allocate time instead for other services
go to ./install_real_time_kernel_for_linux and 
follow the instructions in the readme


### Step 4:  install Amilcar 
 In install_amilcar script, we create system services and run the scripts for GPS, RTC, and reduce latency as explained below,
We reduce latency by running a RT kernel (real-time) by disabling many services, and running headles rPi, check reduce_latency scripts for more details
The service descriptions below are not up to date check install_amilcar.sh instead

run the following commands:
**make the file executable**
```
sudo chmod +x install_amilcar.sh
```
**Run**
```
source install_amilcar.sh
```

And that's it now the GPS, RTC are set and the rPi will start recording,
for more details on what install_amilcar script contains see below,
Note: you only run install_amilcar.sh, what's below is only an explanation that is not the most
up-to-date,


- Set the internal time of the rPi as GPS time
  
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

- check ./GPS to see how to choose the offsett 
 

### Step ': Discipline the RTC using GPS and use RTC as fallback 

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

- Step 6: add audio group to user
```
sudo usermod -aG audio pi
sudo reboot
```

- Step 7: configure ADC+DAC converter
***Run setup_audip.sh***
```
 sudo chmod +x audio/setup_audio.sh
./audio/setup_audio.sh
```

- Step 8: reduce latency

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
- Step 8: Increase audio volume

check /audio for more details
```
amixer -D hw: 0 cset name='ADC Capture Volume' 96,96
sudo alsactl store
```

- Step 9: run the jack server to record audio

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
- Step 10: record audio

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

- Step 11: add a timer for record audio

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

##Ressources:
 https://wiki.linuxaudio.org/wiki/raspberrypi : great discussion on running real time audio using Raspberry Pi and using JACK
https://wiki.linuxaudio.org/wiki/system_configuration#do_i_really_need_a_real-time_kernel




