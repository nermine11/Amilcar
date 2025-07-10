We use hifiberry DAC + ADC PRO tp convert the analog signals from the hydrophone into digital signals since Raspberry Pi can't do that on its own.

Documentation: https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/

https://www.hifiberry.com/docs/hardware/using-dynamic-microphones-with-the-dac-adc/

You will need an updated Linux kernel. You will need at least version 4.18.12. You can check this using the command uname
```
# uname -a
```
Linux hifiberry 4.18.12-v7 #1 SMP ...

After running audio_setup.sh, The system should now list the correct card:
```
# arecord -l
**** List of CAPTURE Hardware Devices ****
card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplusadc], 
 device 0: HiFiBerry DAC+ADC HiFi multicodec-0 []
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```
If you have configured the correct overlay, but the system still doesn’t load the driver, you need to disable the onboard EEPROM by 
running
```
sudo bash -c "echo 'force_eeprom_read=0' >> /boot/firmware/config.txt"
```
