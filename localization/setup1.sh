#!/bin/bash

# Step 1: Latency reduction ]==="
sudo chmod +x /home/pi/Amilcar/audio/reduce_latency_on_boot.sh
source /home/pi/Amilcar/audio/reduce_latency_on_boot.sh

# Step 2: Install Amilcar ]==="
sudo chmod +x install_setup.sh
source install_setup.sh

# Step 3: Setup GPS time ]==="
sudo chmod +x /home/pi/Amilcar/GPS/GPS_setup.sh
source /home/pi/Amilcar/GPS/GPS_setup.sh


#Step 5: Setup get_location service and timer ]==="
cat <<EOF | sudo tee /etc/systemd/system/get_location.service
[Unit]
Description=get location and time every second
After=gpsd.service
Wants=gpsd.service

[Service]
ExecStart=/home/pi/Amilcar/localization/venv/bin/python /home/pi/Amilcar/localization/get_location_continously.py
WorkingDirectory=/home/pi/Amilcar/localization
Restart=always
RestartSec=1
User=pi
TimeoutStopSec=30          # give 30s to shut down cleanly

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/get_location.timer
[Unit]
Description=timer for location server

[Timer]
OnBootSec=15min
Unit=get_location.service

[Install]
WantedBy=timers.target
EOF

# Step 7: Enable systemd units ]==="
sudo systemctl daemon-reload
sudo systemctl enable get_location.timer

echo "===[ Phase 1 Complete. Please reboot manually.== "
