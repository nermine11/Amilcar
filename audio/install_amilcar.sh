#!/bin/bash
set -e  # Stop on first error

#Step 1: Clone or unzip Amilcar repo ===
cd /home/pi/Amilcar

# Step 2: Install real time kernel

# Step 3: Install Amilcar ===
chmod +x install_setup.sh
source install_setup.sh

# Step 4: Setup GPS time
chmod +x GPS/GPS_setup.sh
./GPS/GPS_setup.sh

#Please manually edit /etc/chrony/chrony.conf to comment the following lines:"
##debian vendor zone"
##use time sources from dhcp"
##use ntp sources found in /etc/chrony/chrony.conf"


# Step 6: Add user 'pi' to audio group 
sudo usermod -aG audio pi

# Step 7: Configure ADC+DAC PRO
chmod +x audio/setup_audio.sh
./audio/setup_audio.sh

# Step 8: Reduce latency 
chmod +x audio/reduce_latency_on_boot.sh
./audio/reduce_latency_on_boot.sh
chmod +x audio/reduce_latency.sh
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

# Step 9: Set audio volume 
amixer -D hw:0 cset name='ADC Capture Volume' 96,96
sudo alsactl store

# Step 10: Setup JACK server 
cat <<EOF | sudo tee /etc/systemd/system/jack_server.service
[Unit]
Description=run jack server

[Service]
Restart=always
RestartSec=1
User=pi
Group=audio
ExecStart=/usr/bin/jackd -R -P70 -t 2000 -d alsa -d hw:0 -r 44100 -p2048 -n2

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
