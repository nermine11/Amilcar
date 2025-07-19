#!/bin/bash

##############################################################
# This script has to be placed in /home/pi/Amilcar
##############################################################

# update
apt update
apt install -y python3-venv libjack-jackd2-dev jackd2 i2c-tools


# install and activate the virtual environment
virtualenv -p /usr/bin/python3 venv
source venv/bin/activate

# Install the Python packages needed by the SmartMesh SDK inside the venv
venv/bin/pip install -r /home/pi/Amilcar/requirements.txt --default-timeout=100

