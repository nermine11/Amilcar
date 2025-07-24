#!/bin/bash

#Step 1: Clone or unzip Amilcar repo ===
cd /home/pi/Amilcar

# Step 2: Install real time kernel

# Step 3: Install Amilcar ===
sudo chmod +x install_setup.sh
source install_setup.sh

# Step 4: Setup GPS time
sudo chmod +x GPS/GPS_setup.sh
./GPS/GPS_setup.sh

#Please manually edit /etc/chrony/chrony.conf to comment the following lines:"
##debian vendor zone"
##use time sources from dhcp"
##use ntp sources found in /etc/chrony/chrony.conf"

#step 5: setup RTC

sudo chmod +x RTC/RTC_GPS_sync.sh
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
sudo systemctl start RTC_GPS_sync.service
sudo systemctl enable --now RTC_GPS_sync.service


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



# Step 6: Add user 'pi' to audio group 
sudo usermod -aG audio pi

# Step 6: isolate CPU 3
grep -q 'isolcpus=3' /boot/firmware/cmdline.txt || sudo sed -i 's/$/ isolcpus=3/' /boot/firmware/cmdline.txt

# Step 7: Configure ADC+DAC PRO
sudo chmod +x audio/setup_audio.sh
./audio/setup_audio.sh

# Step 8: Reduce latency 
sudo chmod +x audio/reduce_latency_on_boot.sh
./audio/reduce_latency_on_boot.sh

sudo chmod +x audio/reduce_latency.sh
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


# Step 10: Setup JACK server 
cat <<EOF | sudo tee /etc/systemd/system/jack_server.service
[Unit]
Description=run jack server

[Service]
Restart=always
RestartSec=1
User=pi
Group=audio
ExecStart=/usr/bin/jackd -R -P70 -t 2000 -d alsa -d hw:0 -r 44100 -p 2048 -n2 -i2 -o2
CPUAffinity=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start jack_server.service
sudo systemctl enable --now jack_server.service

#Step 11: Setup audio recording
cat <<EOF | sudo tee /etc/systemd/system/record_audio.service
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
CPUAffinity=3

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/record_audio.timer
[Unit]
Description=timer for Hydrophone Audio Recorder

[Timer]
OnBootSec=10min
Unit=record_audio.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl disable record_audio.service
sudo systemctl start record_audio.timer
sudo systemctl enable --now record_audio.timer

sudo reboot
