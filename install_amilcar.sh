#!/bin/bash

##############################################################
# This script has to be placed in /home/pi/Amilcar
##############################################################

# update
apt update
apt install -y python3-venv libjack-jackd2-dev jackd2 i2c-tools


# install and activate the virtual environment
python3 -m venv venv
source venv/bin/activate

# Install the Python packages needed by Amilcar inside the venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r /home/pi/Amilcar/requirements.txt --default-timeout=100

