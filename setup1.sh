#!/bin/bash

cd /home/pi/Amilcar

# === Step 1: Install Amilcar ===
sudo chmod +x install_setup.sh
source install_setup.sh

# === Step 2: Setup GPS time ===
sudo chmod +x GPS/GPS_setup.sh
./GPS/GPS_setup.sh

echo "===[ Reminder: edit /etc/chrony/chrony.conf manually to disable DHCP/NTP sources ]==="

# === Step 3: Add pi to audio group ===
sudo usermod -aG audio pi

# === Step 4: Isolate CPU 3 ===
grep -q 'isolcpus=3 nohz_full=3 rcu_nocbs=3' /boot/firmware/cmdline.txt || sudo sed -i 's/$/ isolcpus=3 nohz_full=3 rcu_nocbs=3/' /boot/firmware/cmdline.txt

# === Step 5: Configure ADC+DAC PRO ===
sudo chmod +x audio/setup_audio.sh
./audio/setup_audio.sh

# === Step 6: Set ADC volume ===
amixer -D hw:0 cset name='ADC Capture Volume' 96,96
sudo alsactl store

# === Step 7: Reduce latency (on boot and now) ===
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

# === Step 8: JACK server service ===
cat <<EOF | sudo tee /etc/systemd/system/jack_server.service
[Unit]
Description=run jack server

[Service]
User=pi
Group=audio
ExecStart=/usr/bin/jackd -R -P70 -t 2000 -d alsa -d hw:0 -r 44100 -p 2048 -n2 -i2 -o2
Environment=JACK_NO_AUDIO_RESERVATION=1
Restart=always
RestartSec=2
LimitRTPRIO=95
LimitMEMLOCK=infinity
CPUAffinity=3

[Install]
WantedBy=multi-user.target
EOF

# === Step 9: Audio recorder service and timer ===
cat <<EOF | sudo tee /etc/systemd/system/record_audio.service
[Unit]
Description=Hydrophone Audio Recorder
After=jack_server.service gpsd.service
Wants=jack_server.service gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/venv/bin/python /home/pi/Amilcar/audio/record_continously.py
WorkingDirectory=/home/pi/Amilcar
Restart=always
RestartSec=1
User=pi
Group=audio
LimitRTPRIO=infinity
LimitMEMLOCK=infinity
CPUAffinity=3
TimeoutStopSec=30          # give 30s to shut down cleanly

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/record_audio.timer
[Unit]
Description=timer for Hydrophone Audio Recorder

[Timer]
OnBootSec=15min
Unit=record_audio.service

[Install]
WantedBy=timers.target
EOF

# === Step 10: Enable services (not starting them yet) ===
sudo systemctl daemon-reload
sudo systemctl enable reduce_latency.service
sudo systemctl enable jack_server.service
sudo systemctl enable record_audio.timer

# === Final sync and instructions ===
sync
sleep 5
echo "===[ Setup Phase 1 Complete. Please reboot the system manually. ]==="
