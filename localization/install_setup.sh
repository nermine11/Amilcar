#!/bin/bash

##############################################################
# This script has to be placed in /home/pi/Amilcar/localization
##############################################################

# update
sudo apt update
sudo apt install -y python3-venv 


# install and activate the virtual environment
python3 -m venv venv
source venv/bin/activate

# Install the Python packages needed by Amilcar inside the venv
sudo venv/bin/pip install --upgrade pip
sudo venv/bin/pip install -r /home/pi/Amilcar/localization/requirements.txt --default-timeout=100

