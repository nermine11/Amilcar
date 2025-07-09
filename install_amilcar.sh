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

#cd /home/pi/Amilcar

# Update package list and fix broken dependencies
#sudo apt update
#sudo apt install -y python3-venv python3-pip

# Create the virtual environment 
#python3 -m venv venv

# Activate the virtual environment
#source venv/bin/activate

# Upgrade pip (inside venv)
#pip install --upgrade pip

# Install Python packages inside the venv
#pip install -r requirements.txt --default-timeout=100