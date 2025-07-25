#!/bin/bash

##############################################################
# This script has to be placed in /home/pi/Amilcar/localization
##############################################################

#Step 1: isolate CPU 3
grep -q 'isolcpus=3 nohz_full=3 rcu_nocbs=3' /boot/firmware/cmdline.txt || sudo sed -i 's/$/ isolcpus=3 nohz_full=3 rcu_nocbs=3/' /boot/firmware/cmdline.txt


# Step 2: Reduce latency 
sudo chmod +x /home/pi/Amilcar/audio/reduce_latency_on_boot.sh
source /home/pi/Amilcar/audio/reduce_latency_on_boot.sh

sudo chmod +x /home/pi/Amilcar/audio/reduce_latency.sh
cat <<EOF | sudo tee /etc/systemd/system/reduce_latency.service
[Unit]
Description=reduce latency

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/home/pi/Amilcar/audio/reduce_latency.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start reduce_latency.service
sudo systemctl enable --now reduce_latency.service


# Step 3: Install Amilcar ===
sudo chmod +x install_setup.sh
source install_setup.sh

# Step 4: Setup GPS time
sudo chmod +x /home/pi/Amilcar/GPS/GPS_setup.sh
source /home/pi/Amilcar/GPS/GPS_setup.sh

#Please manually edit /etc/chrony/chrony.conf to comment the following lines:"
##debian vendor zone"
##use time sources from dhcp"
##use ntp sources found in /etc/chrony/chrony.conf"


#step 5: setup RTC

sudo chmod +x /home/pi/Amilcar/RTC/RTC_GPS_sync.sh
cat <<EOF | sudo tee /etc/systemd/system/rtc-gps-sync.service
[Unit]
Description=RTC fallback
After=gpsd.service
Wants=gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/RTC/RTC_GPS_sync.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start rtc-gps-sync.service
sudo systemctl enable --now rtc-gps-sync.service


#set timer for RTC

cat <<EOF | sudo tee /etc/systemd/system/rtc-gps-sync.timer
[Unit]
Description=timer for RTC fallback

[Timer]
OnBootSec=10min
Unit=rtc-gps-sync.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl disable rtc-gps-sync.service
sudo systemctl start rtc-gps-sync.timer
sudo systemctl enable --now rtc-gps-sync.timer

#step 5: run the code


cat <<EOF | sudo tee /etc/systemd/system/get_location.service
[Unit]
Description=get location and time every second
After=gpsd.service
Wants=gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/localization/venv/bin/python /home/pi/Amilcar/localization/get_location.py
WorkingDirectory=/home/pi/Amilcar/localization
Restart=always
RestartSec=1
User=pi
LimitRTPRIO=infinity
LimitMEMLOCK=infinity
CPUAffinity=3

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/get_location.timer
[Unit]
Description=timer for location server

[Timer]
OnBootSec=10min
Unit=get_location.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl disable get_location.service
sudo systemctl start get_location.timer
sudo systemctl enable --now get_location.timer

sudo reboot
