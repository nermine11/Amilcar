# remove the line dtparam=audio=on

sudo sed -i '/^dtparam=audio=on$/d' /boot/firmware/config.txt
# Modify vc4-fkms-v3d overlay if present
sudo sed -i 's/^dtoverlay=vc4-fkms-v3d$/dtoverlay=vc4-fkms-v3d,audio=off/'/boot/firmware/config.txt

# Modify vc4-kms-v3d overlay if present
sudo sed -i 's/^dtoverlay=vc4-kms-v3d$/dtoverlay=vc4-kms-v3d,noaudio/' /boot/firmware/config.txt

sudo bash -c "echo 'dtoverlay=hifiberry-dacplusadcpro' >> /boot/firmware/config.txt"
# might need to add
#sudo bash -c "echo 'force_eeprom_read=0 >> /boot/firmware/config.txt"
sudo reboot