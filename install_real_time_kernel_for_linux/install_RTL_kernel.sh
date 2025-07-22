#!/bin/bash

sudo apt update
sudo apt upgrade
sudo rpi-update
#I have linux 6.12.38, choose your kernel version accordingly
cd ~
git clone --depth=1 https://github.com/raspberrypi/linux
cd linux
wget https://www.kernel.org/pub/linux/kernel/projects/rt/6.12/older/patch-6.12-rc1-rt1.patch.gz
gunzip patch-6.12-rc1-rt1.patch.gz
cat patch--6.12-rc1-rt1.patch | patch -p1
cd ~
sudo apt install bc bison flex libssl-dev make
#for rPi 5
cd linux
KERNEL=kernel_2712
make bcm2712_defconfig
