grep -Fxq '#added to charge the RTC battery' /boot/firmware/config.txt || \
echo '#added to charge the RTC battery' | sudo tee -a /boot/firmware/config.txt > /dev/null
grep -Fxq 'dtparam=rtc_bbat_vchg=3000000' /boot/firmware/config.txt || \
echo 'dtparam=rtc_bbat_vchg=3000000' | sudo tee -a /boot/firmware/config.txt > /dev/null
#disable RTC of rPi 5
grep -Fxq 'dtparam=rtc=off' /boot/firmware/config.txt || \
echo 'dtparam=rtc=off' | sudo tee -a /boot/firmware/config.txt > /dev/null


#Disable the "fake hwclock" which interferes with the 'real' hwclock
sudo apt-get -y remove fake-hwclock
sudo update-rc.d -f fake-hwclock remove
sudo systemctl disable fake-hwclock

# Modifying $HWCLOCK_SET_FILE"
HWCLOCK_SET_FILE="/lib/udev/hwclock-set"
# Comment out the systemd exit block
sudo sed -i 's|^\(if \[ -e /run/systemd/system \] ; then\)|#\1|' $HWCLOCK_SET_FILE
sudo sed -i 's|^\(\s*exit 0\)|#\1|' $HWCLOCK_SET_FILE
sudo sed -i 's|^\(fi\)|#\1|' $HWCLOCK_SET_FILE

# Comment out hwclock --systz lines
sudo sed -i 's|^\(/sbin/hwclock --rtc=\$dev --systz --badyear\)|#\1|' $HWCLOCK_SET_FILE
sudo sed -i 's|^\(/sbin/hwclock --rtc=\$dev --systz\)$|#\1|' $HWCLOCK_SET_FILE
