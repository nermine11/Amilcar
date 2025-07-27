## Hardware requirements
-  1 Raspberry Pi 5 for better time precision
-  1 Adafuit ultimate GPS HAT
-  1 GPS antennas for better time accuracy, use the same one as for the recording rPis for better sycnhronization
   -> different GPS antennas can give different results, also having the same GPS antenna means having the same length of the wire so the data takes the same
  amount of time (in nanoseconds) to travel to the GPS HAT so better synchronization!)
-  1 power banks
-  1 rPi5 cooling fans
-  1 SD card 256 GO


### Step 2: Enable SSH using Ethernet cable

- Check the name of ethernet interface using:
```
nmcli device status
```
then run the following command to be able to SSH from your computer to the rPi using an ethernet cable
```
sudo nmcli con mod "name of ethernet interface" ipv4.addresses 192.168.50.2/24 ipv4.gateway 192.168.50.1 ipv4.dns 8.8.8.8 ipv4.method manual

```

### Step 3: Download Amilcar and install real time kernel
go to ./install_real_time_kernel_for_linux and 
follow the instructions in the readme


### Step 4:  install install_location.sh
 In install_location script, we create system services and run the scripts for GPS, RTC, and reduce latency 

run the following commands:
**make the file executable**
```
sudo chmod +x install_location.sh
```
**Run**
```
source install_location.sh
```

And that's it now the GPS, RTC are set and the rPi will start saving the location and its timestamp each second in JSON file

