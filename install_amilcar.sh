#!/bin/bash

##############################################################
# This script has to be placed in /home/pi/Amilcar
##############################################################

# update
sudo apt update
sudo apt install -y virtualenv

# install and activate the virtual environment
sudo virtualenv -p /usr/bin/python3 venv
source venv/bin/activate

# Install the Python packages needed by the SmartMesh SDK inside the venv
sudo venv/bin/pip install -r /home/pi/Amilcar/requirements.txt --default-timeout=100
