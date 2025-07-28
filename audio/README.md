We use hifiberry DAC + ADC PRO to convert the analog signals from the hydrophone into digital signals since Raspberry Pi can't do that on its own.

<img width="300" height="300" alt="image" src="https://github.com/user-attachments/assets/98b15cbb-4b7c-43ad-be3a-2ddac484e75f" />

Documentation: 
https://www.hifiberry.com/docs/data-sheets/datasheet-dac-adc-pro/
https://www.hifiberry.com/docs/software/configuring-linux-3-18-x/

We use the Aquarium H2dM hydrophone: 

<img width="300" height="300" alt="image" src="https://github.com/user-attachments/assets/96e2f575-5d22-4b13-bf0e-a4b18c40ea35" />

https://www.aquarianaudio.com/h2d-hydrophone.html

We use JACK for real time recording:
"JACK (JACK Audio Connection Kit), often referred to as jackd, is a

“system for handling real-time, low latency audio (and MIDI). It runs on GNU/Linux, Solaris, FreeBSD, OS X and Windows (and can be ported to other POSIX-conformant platforms). It can connect a number of different applications to an audio device, as well as allowing them to share audio between themselves. Its clients can run in their own processes (ie. as normal applications), or can they can run within the JACK server (ie. as a “plugin”). JACK also has support for distributing audio processing across a network, both fast & reliable LANs as well as slower, less reliable WANs.

JACK was designed from the ground up for professional audio work, and its design focuses on two key areas: synchronous execution of all clients, and low latency operation.”3)"
We record constantly since reboot after a timer of 30 minutes to give time to get GPS fix,
we save the files each hour in a folder by day
We use wav and inject the GPS timestamps and location each second
To get the timestamps use: 
```
ffprobe -show_entries format_tags=comment filename.wav
```
Example:


<img width="859" height="913" alt="image" src="https://github.com/user-attachments/assets/ae0080e9-c582-467e-9c72-6a80264220f3" />



You will need an updated Linux kernel. You will need at least version 4.18.12. You can check this using the command uname
```
# uname -a
```

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
**Choice of sampling rate and bit depth** 

What we are testing here is the choice of the sampling rate (44.1Khz or 48Khz) and the bit depth(16bit or 24bit)

 Try the following command to record for 3 seconds, bit depth 16, wav format, and show VU meter.
```
arecord -D sysdefault -r 44100 -d 3 -f S16 -t wav -V mono test.wav
```
then test using sampling rate 480000, bit depth 24
```
arecord -D sysdefault -r 48000 -d 3 -f S24 -t wav -V mono test.wav
```
For more explanation about sampling rates and bit depth: https://www.youtube.com/watch?v=5NE3Cx0PClc
https://www.izotope.com/en/learn/digital-audio-basics-sample-rate-and-bit-depth

You will notice that the hydrophone signal is very low. This is expected and we need to boost the signal with the following command:

```
amixer -D sysdefault cset name='ADC Capture Volume' 96,96
```
"The values of this command are steps between 0 and 104 and will set ADC volume 0.5db/step. So 96 is about 48dB. You may adjust this value to a lower level depending on the sensitivity. A 33dB gain should work just fine. You may retry to record again and observe the VU meter levels."
by https://aizerocaliber.com/2021/02/creating-a-smart-hydrophone-processing-system-software/

- If the VU meter levels are too low (1-10%)  increase the gain
- If the VU meter levels are too high(near 10%) reduce the gain

When you find the right value, to save the current setting even after reboot run:
  ```
  sudo alsactl store
  ```
