- From Amilcar run
```
sudo chmod +x install_real_time_kernel_for_linux/install_RTL_kernel.sh
./install_real_time_kernel_for_linux/install_RTL_kernel.sh
```
```
cd ~/linux
make menuconfig
```
- At  General setup > Local version - append to kernel release, change CONFIG_LOCALVERSION from "v8-16k" (depends on what you have 
) to "v8-16k-behai-rt-build" and save and reload

- Activate the first menu item General setup --->. On the next screen, select Preemption Model (Preemptible Kernel (Low-Latency Desktop)) ---> as shown below:

<img width="800" height="433" alt="image" src="https://github.com/user-attachments/assets/65a605ba-f10a-44a9-b416-467009d5a5b8" />

In the pop-up dialog, select ( ) Fully Preemptible Kernel (Real-Time) as per the screenshot below:

<img width="800" height="433" alt="image" src="https://github.com/user-attachments/assets/ba52b59a-ddad-4383-bd9b-371034667878" />

The main screen should show Preemption Model (Fully Preemptible Kernel (Real-Time)) ---> as per the following screenshot:

<img width="800" height="433" alt="image" src="https://github.com/user-attachments/assets/eda96816-c1aa-423d-9d39-5b0c4e8ee97f" />


- Check how many cores you have using
```
nproc
```
In our case, we have 4, 
- run
```
make -j4 Image.gz modules dtbs
```









Images and their explanation from: https://dev.to/behainguyen/raspberry-pi-4b-natively-build-a-64-bit-fully-preemptible-kernel-real-time-with-desktop-1afj


